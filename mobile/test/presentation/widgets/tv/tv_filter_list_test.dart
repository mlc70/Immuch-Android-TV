import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/presentation/widgets/tv/tv_filter_list.dart';
import 'package:immich_mobile/presentation/widgets/tv/tv_shell.widget.dart';

void main() {
  testWidgets('multi-select reaches offscreen row and arrows do not select', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final selected = List.filled(120, false);
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TvShell(child: child!),
      home: Scaffold(body: StatefulBuilder(builder: (context, setState) => FocusScope(
        child: TvFilterList(
          labels: [for (var i = 0; i < 120; i++) 'Person $i'], selected: selected,
          onToggle: (i) => setState(() => selected[i] = !selected[i]),
        ),
      ))),
    ));
    await tester.pumpAndSettle();
    final list = tester.element(find.byType(TvFilterList));
    final node = Focus.of(tester.element(find.byType(ListView)));
    node.requestFocus();
    await tester.pumpAndSettle();
    for (var i = 0; i < 80; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
    }
    expect(selected.any((v) => v), isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(selected[80], isTrue);
    expect(list.mounted, isTrue);
    expect(tester.takeException(), isNull);
  });
}
