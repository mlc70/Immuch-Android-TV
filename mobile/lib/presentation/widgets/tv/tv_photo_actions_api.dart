import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/domain/models/asset/base_asset.model.dart';
import 'package:immich_mobile/presentation/widgets/tv/tv_photo_actions.dart';
import 'package:immich_mobile/providers/api.provider.dart';
import 'package:immich_mobile/providers/infrastructure/album.provider.dart';
import 'package:immich_mobile/providers/infrastructure/asset.provider.dart';
import 'package:immich_mobile/providers/infrastructure/readonly_mode.provider.dart';
import 'package:immich_mobile/providers/user.provider.dart';
import 'package:immich_mobile/repositories/album_api_repository.dart';
import 'package:openapi/api.dart';

/// Only organizational endpoints are exposed; never pixel edits or asset deletion.
Future<void> openTvPhotoActions(BuildContext context, WidgetRef ref, BaseAsset asset, VoidCallback rotate) {
  final api = ref.read(apiServiceProvider);
  final userId = ref.read(currentUserProvider)?.id;
  final writable =
      asset is RemoteAsset &&
      asset.ownerId == userId &&
      !asset.isTrashed &&
      !asset.isLocked &&
      !ref.read(readonlyModeProvider);
  final assetService = ref.read(assetServiceProvider);
  final albums = ref.read(remoteAlbumServiceProvider);
  final albumApi = ref.read(albumApiRepositoryProvider);
  var favorite = asset.isFavorite;

  Future<Map<String, dynamic>> info() async {
    final value = await api.assetsApi.getAssetInfo(asset.id);
    if (value == null) {
      throw StateError('No asset information');
    }
    return jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
  }

  return showTvPhotoActions(
    context: context,
    rotate: rotate,
    isFavorite: favorite,
    favorite: writable
        ? () async {
            await assetService.update([asset.id], isFavorite: .some(!favorite));
            favorite = !favorite;
          }
        : null,
    details: () async {
      final data = asset is RemoteAsset ? await info() : <String, dynamic>{};
      final exif = data['exifInfo'] as Map? ?? {};
      return [
        TvPhotoAction('File: ${asset.name}', null),
        TvPhotoAction('Taken: ${asset.createdAt.toLocal()}', null),
        TvPhotoAction('Size: ${asset.width ?? '?'} × ${asset.height ?? '?'}', null),
        for (final entry in exif.entries)
          if (entry.value != null) TvPhotoAction('${entry.key}: ${entry.value}', null),
      ];
    },
    albums: () async {
      final values = await albums.getAll();
      // Restrict to owned albums; shared viewers must never be offered a write.
      return [
        for (final album in values.where((a) => a.ownerId == userId))
          TvPhotoAction(album.name, () async {
            final result = await albumApi.addAssets(album.id, [asset.id]);
            if (result.failed.isNotEmpty) {
              throw StateError('Album add failed');
            }
          }),
        if (!values.any((a) => a.ownerId == userId)) const TvPhotoAction('No writable albums', null),
      ];
    },
    tags: () async {
      final data = await info();
      final assigned = (data['tags'] as List? ?? []).map((e) => (e as Map)['id']).toSet();
      final values = await api.tagsApi.getAllTags();
      if (values == null) {
        throw StateError('No tags response');
      }
      return [
        for (final tag in values)
          TvPhotoAction('${assigned.contains(tag.id) ? 'Remove' : 'Add'}: ${tag.value}', () async {
            final result = assigned.contains(tag.id)
                ? await api.tagsApi.untagAssets(tag.id, BulkIdsDto(ids: [asset.id]))
                : await api.tagsApi.tagAssets(tag.id, BulkIdsDto(ids: [asset.id]));
            if (result == null || result.isEmpty || result.any((r) => !r.success)) {
              throw StateError('Tag update failed');
            }
          }),
        if (values.isEmpty) const TvPhotoAction('No tags available on this server', null),
      ];
    },
  );
}
