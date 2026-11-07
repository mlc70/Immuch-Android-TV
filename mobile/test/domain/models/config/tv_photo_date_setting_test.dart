import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/domain/models/config/app_config.dart';
import 'package:immich_mobile/domain/models/settings_key.dart';

void main() {
  test('TV date/time defaults to two rows 12 pixels above bottom and persists changes', () {
    const config = AppConfig();
    expect(config.viewer.tvDateTimeSingleLine, isFalse);
    expect(config.viewer.tvDateBottomOffset, 12);
    final configured = config
        .write(SettingsKey.viewerTvDateTimeSingleLine, true)
        .write(SettingsKey.viewerTvDateBottomOffset, 4);
    expect(configured.read(SettingsKey.viewerTvDateTimeSingleLine), isTrue);
    expect(configured.read(SettingsKey.viewerTvDateBottomOffset), 4);
    expect(AppConfig.fromEntries({
      SettingsKey.viewerTvDateTimeSingleLine: false,
      SettingsKey.viewerTvDateBottomOffset: 24,
    }).viewer.tvDateBottomOffset, 24);
  });

  test('Android TV photo date is visible by default', () {
    const config = AppConfig();
    expect(config.viewer.tvShowDateTime, isTrue);
    expect(config.read(SettingsKey.viewerTvShowDateTime), isTrue);
  });

  test('photo date visibility persists in the application settings snapshot', () {
    const config = AppConfig();
    final hidden = config.write(SettingsKey.viewerTvShowDateTime, false);
    expect(hidden.viewer.tvShowDateTime, isFalse);
    expect(hidden.read(SettingsKey.viewerTvShowDateTime), isFalse);

    final restored = AppConfig.fromEntries({SettingsKey.viewerTvShowDateTime: false});
    expect(restored.viewer.tvShowDateTime, isFalse);
    expect(restored.write(SettingsKey.viewerTvShowDateTime, true).viewer.tvShowDateTime, isTrue);
  });
}
