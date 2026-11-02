import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/presentation/widgets/tv/tv_text_entry.widget.dart';
import 'package:immich_mobile/providers/infrastructure/tv.provider.dart';
import 'package:immich_mobile/widgets/common/search_field.dart';

void main() {
  testWidgets('TV Search label and full typing hint fit the app bar at 960x540', (tester) async {
    tester.view.physicalSize = const Size(960, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tvModeProvider.overrideWith((ref) => true)],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(navigationMode: NavigationMode.directional),
            child: child!,
          ),
          home: Scaffold(
            appBar: AppBar(
              title: const SearchField(
                label: 'Search text',
                hintText: 'Sunrise on the beach',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<TvTextEntry>(find.byType(TvTextEntry)).label, 'Search text');
    expect(find.text('Search text'), findsOneWidget);
    expect(find.text('Press OK to type'), findsOneWidget);
    expect(find.text('Sunrise on the beach'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
