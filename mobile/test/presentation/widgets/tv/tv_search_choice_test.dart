import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/presentation/widgets/tv/tv_shell.widget.dart';
import 'package:immich_mobile/presentation/widgets/tv/tv_search_choice.dart';

void main() {
  testWidgets('remote reaches lazy city 80, contains focus and Back cancels', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    int? selected;
    var behind = 0;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TvShell(child: child!),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              autofocus: true,
            onPressed: () async {
                behind++;
                selected = await showTvSearchChoice<int>(
                  context: context,
                  title: const Text('City'),
                  entries: [for (var i = 0; i < 120; i++) DropdownMenuEntry(value: i, label: 'City $i')],
                );
              },
              child: const Text('Open cities'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    for (var i = 0; i < 80; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(selected, 80);
    expect(behind, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.goBack, physicalKey: PhysicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(selected, isNull);
    expect(behind, 2);
    expect(tester.takeException(), isNull);
  });
}
