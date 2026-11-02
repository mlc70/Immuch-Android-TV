import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/presentation/widgets/tv/tv_photo_zoom.dart';
import 'package:immich_mobile/widgets/photo_view/photo_view.dart';
import 'package:immich_mobile/widgets/photo_view/src/utils/photo_view_utils.dart';

void main() {
  testWidgets('hold OK at 1x opens actions once and never short presses', (tester) async {
    final photo = PhotoViewController(initialScale: 1)
      ..scaleBoundaries = const ScaleBoundaries(1.0, 20.0, 1.0, Size(960, 540), Size(960, 540));
    final zoom = TvPhotoZoom()..controller = photo;
    var actions = 0;
    var short = 0;
    zoom.ok(
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.enter,
        logicalKey: LogicalKeyboardKey.enter,
        timeStamp: Duration.zero,
      ),
      () => short++,
      onActions: () => actions++,
    );
    await tester.pump(const Duration(milliseconds: 600));
    zoom.ok(
      const KeyUpEvent(
        physicalKey: PhysicalKeyboardKey.enter,
        logicalKey: LogicalKeyboardKey.enter,
        timeStamp: Duration.zero,
      ),
      () => short++,
      onActions: () => actions++,
    );
    expect(actions, 1);
    expect(short, 0);
    expect(zoom.panning, isFalse);
    zoom.dispose();
    photo.dispose();
  });
  testWidgets('960x540 remote zoom, hold OK, pan, exit and reset', (tester) async {
    tester.view.physicalSize = const Size(960, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final photo = PhotoViewController(initialScale: 1)
      ..scaleBoundaries = const ScaleBoundaries(1.0, 20.0, 1.0, Size(960, 540), Size(960, 540));
    final zoom = TvPhotoZoom()..controller = photo;
    addTearDown(zoom.dispose);
    addTearDown(photo.dispose);
    var shortPresses = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Focus(
          autofocus: true,
          onKeyEvent: (_, event) {
            if (event.logicalKey == LogicalKeyboardKey.select) {
              zoom.ok(event, () => shortPresses++);
            } else if (event is! KeyUpEvent) {
              zoom.arrow(event.logicalKey);
            }
            return KeyEventResult.handled;
          },
          child: const SizedBox.expand(),
        ),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    expect(zoom.factor, 1.25);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
    expect(zoom.panning, isTrue);
    expect(shortPresses, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(photo.value.position.dx, -48);
    for (var i = 0; i < 20; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    }
    expect(photo.value.position.dx, -120);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect(zoom.panning, isFalse);
    expect(shortPresses, 0);
    expect(zoom.back(), isTrue);
    expect(zoom.factor, 1);
    expect(photo.value.position, Offset.zero);
    expect(zoom.back(), isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect(shortPresses, 1);
  });

  testWidgets('cancelled hold cannot enter pan or activate controls', (tester) async {
    final photo = PhotoViewController(initialScale: 2)
      ..scaleBoundaries = const ScaleBoundaries(1.0, 20.0, 1.0, Size(960, 540), Size(960, 540));
    final zoom = TvPhotoZoom()..controller = photo;
    var pressed = false;
    zoom.ok(
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.enter,
        logicalKey: LogicalKeyboardKey.enter,
        timeStamp: Duration.zero,
      ),
      () => pressed = true,
    );
    zoom.cancelHold();
    await tester.pump(const Duration(seconds: 1));
    zoom.ok(
      const KeyUpEvent(
        physicalKey: PhysicalKeyboardKey.enter,
        logicalKey: LogicalKeyboardKey.enter,
        timeStamp: Duration.zero,
      ),
      () => pressed = true,
    );
    expect(zoom.panning, isFalse);
    expect(pressed, isFalse);
    zoom.dispose();
    photo.dispose();
  });
}
