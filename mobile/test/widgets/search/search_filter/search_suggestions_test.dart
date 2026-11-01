import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/infrastructure/repositories/search_api.repository.dart';
import 'package:immich_mobile/providers/search/search_filter.provider.dart';
import 'package:immich_mobile/services/api.service.dart';
import 'package:immich_mobile/services/search.service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openapi/api.dart';

class _Api extends Mock implements ApiService {}

class _Search extends Mock implements SearchApiRepository {}

void main() {
  test('suggestion failures remain errors, retry succeeds with unique sorted values', () async {
    final repo = _Search();
    final container = ProviderContainer(
      overrides: [searchServiceProvider.overrideWithValue(SearchService(_Api(), repo))],
    );
    addTearDown(container.dispose);
    const args = SearchSuggestionArgs(type: SearchSuggestionType.country);
    final provider = getSearchSuggestionsProvider(args);
    when(
      () =>
          repo.getSearchSuggestions(SearchSuggestionType.country, country: null, state: null, make: null, model: null),
    ).thenThrow(StateError('offline'));
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    await expectLater(container.read(provider.future), throwsStateError);
    expect(container.read(provider).hasError, isTrue);
    when(
      () =>
          repo.getSearchSuggestions(SearchSuggestionType.country, country: null, state: null, make: null, model: null),
    ).thenAnswer((_) async => ['USA', '', 'Canada', 'USA']);
    container.invalidate(provider);
    expect(await container.read(provider.future), ['Canada', 'USA']);
  });
}
