import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/presentation/widgets/search/tv_date_range.dart';
import 'package:immich_mobile/presentation/widgets/tv/tv_shell.widget.dart';

void main() {
  testWidgets('year first remote choice clamps leap day and keeps ordered range', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    DateTime? start;
    DateTime? end;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TvShell(child: child!),
        home: Scaffold(
          body: TvDateRange(
            start: DateTime(2024, 2, 29),
            end: DateTime(2024, 3, 1),
            onChanged: (a, b) {
              start = a;
              end = b;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('start_0')));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(start, DateTime(2023, 2, 28));
    expect(end, DateTime(2024, 3, 1));
    await tester.tap(find.byKey(const ValueKey('start_0')));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.goBack, physicalKey: PhysicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(start, DateTime(2023, 2, 28));
    expect(tester.takeException(), isNull);
  });
}
