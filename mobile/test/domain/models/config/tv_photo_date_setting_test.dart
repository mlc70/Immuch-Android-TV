import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/domain/models/config/app_config.dart';
import 'package:immich_mobile/domain/models/settings_key.dart';

void main() {
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
