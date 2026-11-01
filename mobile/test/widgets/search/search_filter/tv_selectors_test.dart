import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/constants/locales.dart';
import 'package:immich_mobile/generated/codegen_loader.g.dart';
import 'package:immich_mobile/models/search/search_filter.model.dart';
import 'package:immich_mobile/providers/search/search_filter.provider.dart';
import 'package:immich_mobile/presentation/widgets/tv/tv_shell.widget.dart';
import 'package:immich_mobile/widgets/search/search_filter/location_picker.dart';
import 'package:immich_mobile/widgets/search/search_filter/camera_picker.dart';
import 'package:immich_mobile/widgets/search/search_filter/filter_bottom_sheet_scaffold.dart';
import 'package:immich_mobile/widgets/search/search_filter/search_filter_utils.dart';
import 'package:openapi/api.dart';

void main() {
  Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyEvent(key);
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester, Widget picker, List<SearchSuggestionArgs> requests) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [getSearchSuggestionsProvider.overrideWith((ref, args) async {
        requests.add(args);
        return switch (args.type) {
          SearchSuggestionType.country => ['USA', 'Canada'],
          SearchSuggestionType.state => args.locationCountry == 'Canada' ? ['Ontario'] : ['California'],
          SearchSuggestionType.city => args.locationState == 'Ontario' ? ['Toronto'] : ['San Francisco'],
          SearchSuggestionType.cameraMake => ['Canon', 'Sony'],
          SearchSuggestionType.cameraModel => args.make == 'Sony' ? ['A7'] : ['R5'],
          _ => <String>[],
        };
      })],
      child: EasyLocalization(
        supportedLocales: locales.values.toList(), path: translationsPath,
        startLocale: locales.values.first, fallbackLocale: locales.values.first,
        saveLocale: false, assetLoader: const CodegenLoader(),
        child: Builder(builder: (context) => MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales, locale: context.locale,
          builder: (context, child) => TvShell(child: child!),
          home: Scaffold(body: Builder(builder: (context) => TextButton(
            autofocus: true,
            onPressed: () => showFilterBottomSheet(context: context, child: FilterBottomSheetScaffold(
              title: 'Selector', tvActionRail: true, onSearch: () {}, onClear: () {},
              child: Padding(padding: const EdgeInsets.all(16), child: picker),
            )),
            child: const Text('Open'),
          ))),
        )),
      ),
    ));
    await tester.pumpAndSettle();
    await press(tester, LogicalKeyboardKey.select);
  }

  testWidgets('country change clears dependent state, requests unfiltered countries and scoped cities', (tester) async {
    final requests = <SearchSuggestionArgs>[];
    Map<String, String?>? draft;
    await open(tester, LocationPicker(
      filter: const SearchLocationFilter(country: 'USA', state: 'California', city: 'San Francisco'),
      onSelected: (value) => draft = value,
    ), requests);
    await press(tester, LogicalKeyboardKey.select);
    await press(tester, LogicalKeyboardKey.arrowDown);
    await press(tester, LogicalKeyboardKey.select);
    expect(draft, {'country': 'Canada', 'state': null, 'city': null});
    await press(tester, LogicalKeyboardKey.arrowDown);
    await press(tester, LogicalKeyboardKey.select);
    await press(tester, LogicalKeyboardKey.select);
    expect(draft, {'country': 'Canada', 'state': 'Ontario', 'city': null});
    await press(tester, LogicalKeyboardKey.arrowDown);
    await press(tester, LogicalKeyboardKey.select);
    await press(tester, LogicalKeyboardKey.select);
    expect(draft, {'country': 'Canada', 'state': 'Ontario', 'city': 'Toronto'});
    expect(requests.where((a) => a.type == SearchSuggestionType.country).every((a) => a.locationCountry == null && a.locationState == null), isTrue);
    expect(requests.any((a) => a.type == SearchSuggestionType.city && a.locationCountry == 'Canada' && a.locationState == 'Ontario'), isTrue);
    await press(tester, LogicalKeyboardKey.arrowRight);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'TV filter apply');
    await press(tester, LogicalKeyboardKey.select);
    expect(find.text('Selector'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('make change clears model then model list follows the selected make', (tester) async {
    final requests = <SearchSuggestionArgs>[];
    Map<String, String?>? draft;
    await open(tester, CameraPicker(
      filter: const SearchCameraFilter(make: 'Canon', model: 'R5'),
      onSelect: (value) => draft = value,
    ), requests);
    await press(tester, LogicalKeyboardKey.select);
    await press(tester, LogicalKeyboardKey.arrowDown);
    await press(tester, LogicalKeyboardKey.select);
    expect(draft, {'make': 'Sony', 'model': null});
    await press(tester, LogicalKeyboardKey.arrowDown);
    await press(tester, LogicalKeyboardKey.select);
    await press(tester, LogicalKeyboardKey.select);
    expect(draft, {'make': 'Sony', 'model': 'A7'});
    expect(requests.any((a) => a.type == SearchSuggestionType.cameraModel && a.make == 'Sony'), isTrue);
    expect(tester.takeException(), isNull);
  });
}
