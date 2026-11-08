import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/presentation/widgets/tv/tv_photo_date_overlay.dart';
import 'package:immich_mobile/widgets/settings/asset_viewer_settings/tv_photo_date_position_control.dart';

void main() {
  testWidgets('photo date uses the exact bottom distance despite TV overscan', (tester) async {
    for (final offset in [0, 12, 80]) {
      for (final bottomPadding in [27.0, 0.0, 48.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(padding: EdgeInsets.fromLTRB(48, 27, 48, bottomPadding)),
              child: Scaffold(
                body: Stack(
                  key: const ValueKey('photo'),
                  children: [TvPhotoDateOverlay(bottomOffset: offset, child: const Text('Date\nTime'))],
                ),
              ),
            ),
          ),
        );
        final photo = tester.getRect(find.byKey(const ValueKey('photo')));
        final label = tester.getRect(find.byType(DecoratedBox).last);
        expect(photo.bottom - label.bottom, offset.toDouble());
      }
    }
  });

  testWidgets('remote adjustments update immediately and save the last value in order', (tester) async {
    final firstSave = Completer<void>();
    final saves = <int>[];
    var stored = 12;
    Future<void> save(int value) async {
      saves.add(value);
      if (saves.length == 1) await firstSave.future;
      stored = value;
    }

    Widget settings() => MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(navigationMode: NavigationMode.directional),
        child: Scaffold(
          body: TvPhotoDatePositionControl(value: stored, onSave: save, singleLine: false),
        ),
      ),
    );
    await tester.pumpWidget(settings());
    await tester.pumpAndSettle();
    tester
        .widget<FocusableActionDetector>(
          find.descendant(of: find.byType(Slider), matching: find.byType(FocusableActionDetector)),
        )
        .focusNode!
        .requestFocus();
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
    }
    expect(tester.widget<Slider>(find.byType(Slider)).value, 24);
    expect(find.text('24 px · Left: lower · Right: higher'), findsOneWidget);
    expect(saves, [16]);
    firstSave.complete();
    await tester.pumpAndSettle();
    expect(saves, [16, 24]);
    expect(stored, 24);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(settings());
    expect(tester.widget<Slider>(find.byType(Slider)).value, 24);
  });
}
