import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/domain/models/asset/base_asset.model.dart';
import 'package:immich_mobile/presentation/widgets/tv/tv_album_permissions.dart';
import 'package:immich_mobile/presentation/widgets/tv/tv_photo_actions.dart';
import 'package:immich_mobile/providers/api.provider.dart';
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
  final albumApi = ref.read(albumApiRepositoryProvider);
  var favorite = asset.isFavorite;

  Future<Map<String, dynamic>> info() async {
    final value = await api.assetsApi.getAssetInfo(asset.id);
    if (value == null) {
      throw StateError('No asset information');
    }
    return jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
  }

  Future<dynamic> request(
    String path, {
    String method = 'GET',
    List<QueryParam> query = const [],
    Map<String, dynamic>? body,
  }) async {
    final response = await api.apiClient.invokeAPI(path, method, query, body, {}, {}, 'application/json');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Photo action failed (${response.statusCode})');
    }
    return response.body.isEmpty ? null : jsonDecode(response.body);
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
      final values = (await request('/albums') as List).cast<Map<String, dynamic>>();
      final members = (await request('/albums', query: [QueryParam('assetId', asset.id)]) as List)
          .map((a) => (a as Map)['id'])
          .toSet();
      values.sort((a, b) {
        final membership = (members.contains(b['id']) ? 1 : 0) - (members.contains(a['id']) ? 1 : 0);
        return membership != 0
            ? membership
            : (a['albumName'] as String).toLowerCase().compareTo((b['albumName'] as String).toLowerCase());
      });
      return [
        for (final album in values)
          TvPhotoAction(
            '${members.contains(album['id']) ? '★ ' : ''}${album['albumName']}',
            members.contains(album['id']) || !tvAlbumCanEdit(album, userId)
                ? null
                : () async {
                    final result = await albumApi.addAssets(album['id'] as String, [asset.id]);
                    if (result.failed.isNotEmpty) {
                      throw StateError('Album add failed');
                    }
                  },
            emphasized: members.contains(album['id']),
          ),
        if (values.isEmpty) const TvPhotoAction('No albums available', null),
      ];
    },
    rating: writable
        ? () async {
            final data = await info();
            final current = (data['exifInfo'] as Map?)?['rating'];
            return [
              for (var stars = 1; stars <= 5; stars++)
                TvPhotoAction('${current == stars ? '★ ' : ''}$stars stars', () async {
                  await request('/assets/${asset.id}', method: 'PUT', body: {'rating': stars});
                }, emphasized: current == stars),
              TvPhotoAction('Clear Rating', () async {
                await request('/assets/${asset.id}', method: 'PUT', body: {'rating': null});
              }),
            ];
          }
        : null,
    location: writable
        ? () async {
            final query = await tvPhotoTextInput(context, 'Add / Change Location · Search places');
            if (query == null || query.trim().isEmpty) {
              return [];
            }
            final places = await request('/search/places', query: [QueryParam('name', query.trim())]) as List;
            return [
              for (final place in places.cast<Map<String, dynamic>>())
                TvPhotoAction(
                  [place['name'], place['admin1name'], place['country']].where((v) => v != null && v != '').join(', '),
                  () async {
                    if (!context.mounted) {
                      return;
                    }
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Confirm Location'),
                        content: Text('${place['name']}\n${place['latitude']}, ${place['longitude']}'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(true),
                            child: const Text('Save Location'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await request(
                        '/assets/${asset.id}',
                        method: 'PUT',
                        body: {'latitude': place['latitude'], 'longitude': place['longitude']},
                      );
                    }
                  },
                ),
              if (places.isEmpty) const TvPhotoAction('No places found · Back to search again', null),
            ];
          }
        : null,
    tags: () async {
      final data = await info();
      final assigned = (data['tags'] as List? ?? []).map((e) => (e as Map)['id']).toSet();
      final values = await api.tagsApi.getAllTags();
      if (values == null) {
        throw StateError('No tags response');
      }
      values.sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));
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
