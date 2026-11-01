import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/generated/translations.g.dart';
import 'package:immich_mobile/models/search/search_filter.model.dart';
import 'package:immich_mobile/providers/search/search_filter.provider.dart';
import 'package:immich_mobile/widgets/search/search_filter/common/dropdown.dart';
import 'package:openapi/api.dart';

class CameraPicker extends HookConsumerWidget {
  const CameraPicker({super.key, required this.onSelect, this.filter});

  final Function(Map<String, String?>) onSelect;
  final SearchCameraFilter? filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final makeTextController = useTextEditingController(text: filter?.make);
    final modelTextController = useTextEditingController(text: filter?.model);
    final selectedMake = useState<String?>(filter?.make);
    final selectedModel = useState<String?>(filter?.model);

    final make = ref.watch(
      getSearchSuggestionsProvider(const SearchSuggestionArgs(type: SearchSuggestionType.cameraMake)),
    );

    final models = ref.watch(
      getSearchSuggestionsProvider(
        SearchSuggestionArgs(type: SearchSuggestionType.cameraModel, make: selectedMake.value),
      ),
    );

    final makeWidget = SearchDropdown(
      loading: make.isLoading,
      onRetry: make.hasError
          ? () => ref.invalidate(
              getSearchSuggestionsProvider(const SearchSuggestionArgs(type: SearchSuggestionType.cameraMake)),
            )
          : null,
      dropdownMenuEntries: switch (make) {
        AsyncError() => [],
        AsyncData(:final value) => value.map((e) => DropdownMenuEntry(value: e, label: e)).toList(),
        _ => [],
      },
      label: Text(context.t.make),
      controller: makeTextController,
      leadingIcon: const Icon(Icons.photo_camera_rounded),
      onSelected: (value) {
        if (value.toString() == selectedMake.value) {
          return;
        }
        selectedMake.value = value.toString();
        selectedModel.value = null;
        modelTextController.value = TextEditingValue.empty;
        onSelect({'make': selectedMake.value, 'model': null});
      },
    );

    final modelWidget = SearchDropdown(
      loading: models.isLoading,
      onRetry: models.hasError
          ? () => ref.invalidate(
              getSearchSuggestionsProvider(
                SearchSuggestionArgs(type: SearchSuggestionType.cameraModel, make: selectedMake.value),
              ),
            )
          : null,
      dropdownMenuEntries: switch (models) {
        AsyncError() => [],
        AsyncData(:final value) => value.map((e) => DropdownMenuEntry(value: e, label: e)).toList(),
        _ => [],
      },
      label: Text(context.t.model),
      controller: modelTextController,
      leadingIcon: const Icon(Icons.camera),
      onSelected: (value) {
        selectedModel.value = value.toString();
        onSelect({'make': selectedMake.value, 'model': selectedModel.value});
      },
    );

    if (context.isMobile || MediaQuery.navigationModeOf(context) == NavigationMode.directional) {
      return Column(children: [makeWidget, const SizedBox(height: 8), modelWidget]);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(child: makeWidget),
        const SizedBox(width: 16),
        Expanded(child: modelWidget),
      ],
    );
  }
}
