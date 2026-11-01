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
import 'package:immich_mobile/data/store.dart';
import 'package:immich_mobile/domain/models/person.model.dart';
import 'package:immich_mobile/domain/models/tag.model.dart';
import 'package:immich_mobile/widgets/search/search_filter/people_picker.dart';
import 'package:immich_mobile/widgets/common/tag_picker.dart';
import 'package:immich_mobile/widgets/search/search_filter/media_type_picker.dart';
import 'package:immich_mobile/widgets/search/search_filter/star_rating_picker.dart';
import 'package:immich_mobile/widgets/search/search_filter/display_option_picker.dart';
import 'package:immich_mobile/domain/models/asset/base_asset.model.dart';
import 'package:immich_mobile/presentation/widgets/search/tv_date_range.dart';
import 'package:immich_mobile/presentation/widgets/search/tv_text_search_mode.dart';
import 'package:immich_mobile/providers/infrastructure/tv.provider.dart';
import 'package:immich_mobile/constants/enums.dart';

void main() {
  Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyEvent(key);
    await tester.pumpAndSettle();
  }

  Future<void> open(
    WidgetTester tester,
    Widget picker,
    List<SearchSuggestionArgs> requests, {
    List<Override> overrides = const [],
    VoidCallback? onApply,
    VoidCallback? onClear,
  }) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tvModeProvider.overrideWithValue(true),
          ...overrides,
          getSearchSuggestionsProvider.overrideWith((ref, args) async {
            requests.add(args);
            return switch (args.type) {
              SearchSuggestionType.country => ['USA', 'Canada'],
              SearchSuggestionType.state => args.locationCountry == 'Canada' ? ['Ontario'] : ['California'],
              SearchSuggestionType.city => args.locationState == 'Ontario' ? ['Toronto'] : ['San Francisco'],
              SearchSuggestionType.cameraMake => ['Canon', 'Sony'],
              SearchSuggestionType.cameraModel => args.make == 'Sony' ? ['A7'] : ['R5'],
              _ => <String>[],
            };
          }),
        ],
        child: EasyLocalization(
          supportedLocales: locales.values.toList(),
          path: translationsPath,
          startLocale: locales.values.first,
          fallbackLocale: locales.values.first,
          saveLocale: false,
          assetLoader: const CodegenLoader(),
          child: Builder(
            builder: (context) => MaterialApp(
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              builder: (context, child) => TvShell(child: child!),
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    autofocus: true,
                    onPressed: () => showFilterBottomSheet(
                      context: context,
                      child: FilterBottomSheetScaffold(
                        title: 'Selector',
                        tvActionRail: true,
                        onSearch: onApply ?? () {},
                        onClear: onClear ?? () {},
                        child: Padding(padding: const EdgeInsets.all(16), child: picker),
                      ),
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await press(tester, LogicalKeyboardKey.select);
  }

  testWidgets('country change clears dependent state, requests unfiltered countries and scoped cities', (tester) async {
    final requests = <SearchSuggestionArgs>[];
    Map<String, String?>? draft;
    await open(
      tester,
      LocationPicker(
        filter: const SearchLocationFilter(country: 'USA', state: 'California', city: 'San Francisco'),
        onSelected: (value) => draft = value,
      ),
      requests,
    );
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
    expect(
      requests
          .where((a) => a.type == SearchSuggestionType.country)
          .every((a) => a.locationCountry == null && a.locationState == null),
      isTrue,
    );
    expect(
      requests.any(
        (a) => a.type == SearchSuggestionType.city && a.locationCountry == 'Canada' && a.locationState == 'Ontario',
      ),
      isTrue,
    );
    await press(tester, LogicalKeyboardKey.arrowRight);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'TV filter apply');
    await press(tester, LogicalKeyboardKey.select);
    expect(find.text('Selector'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('make change clears model then model list follows the selected make', (tester) async {
    final requests = <SearchSuggestionArgs>[];
    Map<String, String?>? draft;
    await open(
      tester,
      CameraPicker(
        filter: const SearchCameraFilter(make: 'Canon', model: 'R5'),
        onSelect: (value) => draft = value,
      ),
      requests,
    );
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

  testWidgets('People remote list reaches person 80 and returns from Apply', (tester) async {
    final people = [for (var i = 0; i < 120; i++) Person(id: '$i', name: 'Person $i')];
    Set<Person> selected = {};
    await open(
      tester,
      PeoplePicker(onSelect: (value) => selected = value),
      [],
      overrides: [Store.people.all().overrideWith((ref) => Stream.value(people))],
    );
    await press(tester, LogicalKeyboardKey.arrowDown);
    for (var i = 0; i < 80; i++) {
      await press(tester, LogicalKeyboardKey.arrowDown);
    }
    await press(tester, LogicalKeyboardKey.select);
    expect(selected.single.id, '80');
    await press(tester, LogicalKeyboardKey.arrowRight);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'TV filter apply');
    await press(tester, LogicalKeyboardKey.arrowLeft);
    await press(tester, LogicalKeyboardKey.select);
    expect(selected, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tags remote list reaches tag 80 without changing underlying page', (tester) async {
    final tags = [for (var i = 0; i < 120; i++) Tag(id: '$i', value: 'Tag $i')];
    Iterable<Tag> selected = [];
    await open(
      tester,
      TagPicker(initialSelection: {}, onSelectExistingTag: (value) => selected = value),
      [],
      overrides: [Store.tags.all().overrideWith((ref) async => tags)],
    );
    await press(tester, LogicalKeyboardKey.arrowDown);
    for (var i = 0; i < 80; i++) {
      await press(tester, LogicalKeyboardKey.arrowDown);
    }
    await press(tester, LogicalKeyboardKey.select);
    expect(selected.single.id, '80');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Selector'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final kind in ['Media Type', 'Rating', 'Display']) {
    testWidgets('$kind changes only with OK, then reaches Apply and Clear', (tester) async {
      Object? draft;
      var applied = 0;
      var cleared = 0;
      final picker = switch (kind) {
        'Media Type' => MediaTypePicker(onSelect: (value) => draft = value),
        'Rating' => StarRatingPicker(onSelect: (value) => draft = value),
        _ => DisplayOptionPicker(onSelect: (value) => draft = value),
      };
      await open(tester, picker, [], onApply: () => applied++, onClear: () => cleared++);
      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(draft, isNull);
      await press(tester, LogicalKeyboardKey.select);
      if (kind == 'Media Type') expect(draft, AssetType.image);
      if (kind == 'Rating') expect((draft as SearchRatingFilter).rating.unwrapOrNull, 1);
      if (kind == 'Display') expect((draft as Map<DisplayOption, bool>)[DisplayOption.favorite], isTrue);
      expect(applied, 0);
      await press(tester, LogicalKeyboardKey.arrowRight);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'TV filter apply');
      await press(tester, LogicalKeyboardKey.select);
      expect(applied, 1);
      await press(tester, LogicalKeyboardKey.select);
      await press(tester, LogicalKeyboardKey.arrowRight);
      await press(tester, LogicalKeyboardKey.arrowUp);
      await press(tester, LogicalKeyboardKey.select);
      expect(cleared, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Date range edits draft and Back leaves the active query unchanged', (tester) async {
    var applied = 0;
    DateTime? draft;
    await open(
      tester,
      TvDateRange(start: DateTime(2024, 2, 29), end: DateTime(2024, 3, 1), onChanged: (a, b) => draft = a),
      [],
      onApply: () => applied++,
    );
    await press(tester, LogicalKeyboardKey.select);
    await press(tester, LogicalKeyboardKey.arrowDown);
    await press(tester, LogicalKeyboardKey.select);
    expect(draft, DateTime(2023, 2, 28));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(applied, 0);
    expect(find.text('Selector'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final capabilities in [true, false]) {
    testWidgets('text modes respect server features: $capabilities', (tester) async {
      TextSearchType? selected;
      await open(
        tester,
        Builder(
          builder: (context) => OutlinedButton(
            onPressed: () async => selected = await showTvTextSearchMode(
              context: context,
              current: selected ?? (capabilities ? TextSearchType.context : TextSearchType.filename),
              smartSearch: capabilities,
              ocr: capabilities,
            ),
            child: const Text('Text modes'),
          ),
        ),
        [],
      );
      await press(tester, LogicalKeyboardKey.select);
      await press(tester, LogicalKeyboardKey.arrowDown);
      await press(tester, LogicalKeyboardKey.select);
      expect(selected, capabilities ? TextSearchType.filename : TextSearchType.description);
      if (capabilities) {
        await press(tester, LogicalKeyboardKey.select);
        await press(tester, LogicalKeyboardKey.arrowDown);
        await press(tester, LogicalKeyboardKey.arrowDown);
        await press(tester, LogicalKeyboardKey.select);
        expect(selected, TextSearchType.ocr);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
