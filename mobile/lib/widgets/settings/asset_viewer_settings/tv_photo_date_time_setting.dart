import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/providers/infrastructure/settings.provider.dart';
import 'package:immich_mobile/providers/infrastructure/tv.provider.dart';
import 'package:immich_ui/immich_ui.dart';

/// On TVs the photo's date and time appear at bottom-left by default.
/// Users can hide them without changing any photo metadata.
class TvPhotoDateTimeSetting extends ConsumerWidget {
  const TvPhotoDateTimeSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(tvModeProvider)) {
      return const SizedBox.shrink();
    }

    final showDateTime = ref.watch(appConfigProvider.select((config) => config.viewer.tvShowDateTime));
    final singleLine = ref.watch(appConfigProvider.select((config) => config.viewer.tvDateTimeSingleLine));
    final offset = ref.watch(appConfigProvider.select((config) => config.viewer.tvDateBottomOffset));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSubTitle(title: 'Android TV photo information'),
        SwitchListTile(
          title: const Text('Show photo date and time'),
          subtitle: const Text('Show at bottom-left while photo controls are visible'),
          value: showDateTime,
          onChanged: (value) => unawaited(ref.read(settingsProvider).write(.viewerTvShowDateTime, value)),
        ),
        SwitchListTile(
          title: const Text('Single-line photo date/time'),
          subtitle: const Text('Off shows date above time (recommended for TV)'),
          value: singleLine,
          onChanged: (value) => unawaited(ref.read(settingsProvider).write(.viewerTvDateTimeSingleLine, value)),
        ),
        ListTile(title: const Text('Distance from bottom'), subtitle: Text('$offset px')),
        Slider(
          value: offset.clamp(0, 80).toDouble(),
          min: 0,
          max: 80,
          divisions: 20,
          label: '$offset px',
          onChanged: (value) => unawaited(ref.read(settingsProvider).write(.viewerTvDateBottomOffset, value.round())),
        ),
      ],
    );
  }
}
