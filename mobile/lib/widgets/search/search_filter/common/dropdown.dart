import 'package:flutter/material.dart';
import 'package:immich_mobile/presentation/widgets/tv/tv_search_choice.dart';

class SearchDropdown<T> extends StatelessWidget {
  const SearchDropdown({
    super.key,
    required this.dropdownMenuEntries,
    required this.controller,
    this.onSelected,
    this.label,
    this.leadingIcon,
  });

  final List<DropdownMenuEntry<T>> dropdownMenuEntries;
  final TextEditingController controller;
  final void Function(T?)? onSelected;
  final Widget? label;
  final Widget? leadingIcon;

  static const WidgetStatePropertyAll<EdgeInsetsGeometry> _optionPadding = WidgetStatePropertyAll<EdgeInsetsGeometry>(
    EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
  );

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.navigationModeOf(context) == NavigationMode.directional) {
      return ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, text, _) => OutlinedButton(
          onPressed: () async {
            final current = dropdownMenuEntries.where((e) => e.label == controller.text).firstOrNull?.value;
            final value = await showTvSearchChoice<T>(
              context: context,
              title: label ?? const Text('Select'),
              entries: dropdownMenuEntries,
              current: current,
            );
            if (value == null || !context.mounted) return;
            controller.text = dropdownMenuEntries.firstWhere((e) => e.value == value).label;
            onSelected?.call(value);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                if (leadingIcon != null) leadingIcon!,
                if (label != null) label!,
                const SizedBox(width: 16),
                Expanded(child: Text(text.text.isEmpty ? 'Any' : text.text, overflow: TextOverflow.ellipsis)),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      );
    }
    final mediaQuery = MediaQuery.of(context);
    final maxMenuHeight = mediaQuery.size.height * 0.5 - mediaQuery.viewPadding.bottom;
    const menuStyle = MenuStyle(
      shape: WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final styledEntries = dropdownMenuEntries
            .map(
              (entry) => DropdownMenuEntry<T>(
                value: entry.value,
                label: entry.label,
                labelWidget: entry.labelWidget,
                enabled: entry.enabled,
                leadingIcon: entry.leadingIcon,
                trailingIcon: entry.trailingIcon,
                style: (entry.style ?? const ButtonStyle()).copyWith(padding: _optionPadding),
              ),
            )
            .toList(growable: false);

        return DropdownMenu(
          controller: controller,
          leadingIcon: leadingIcon,
          width: constraints.maxWidth,
          menuHeight: maxMenuHeight,
          dropdownMenuEntries: styledEntries,
          label: label,
          menuStyle: menuStyle,
          trailingIcon: const Icon(Icons.arrow_drop_down_rounded),
          selectedTrailingIcon: const Icon(Icons.arrow_drop_up_rounded),
          onSelected: onSelected,
        );
      },
    );
  }
}
