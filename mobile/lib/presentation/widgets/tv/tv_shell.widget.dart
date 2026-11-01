import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:immich_mobile/presentation/widgets/tv/tv_focus_ring.widget.dart';

/// The remote control layout (Android TV, or the setting turned on), around the whole app in the builder of
/// MaterialApp, under the theme and above the navigator:
/// - Flutter's own TV mode (NavigationMode.directional: disabled controls stay focusable, a slider leaves up and down
///   to the focus);
/// - overscan margins of 5% (48 x 27 dp), as the TV guidelines ask: TVs may cut the edges of the picture, and app
///   bars, rails, dialogs and the overlays of the viewers read MediaQuery.padding, while full screen media still fill
///   the screen;
/// - channel up and down scroll a page, and up and down leave a text field (a single line field keeps them for its
///   caret otherwise, and the focus would be stuck in it);
/// - the arrows move the focus out of a group of radio buttons too, and OK picks a choice (see
///   [radioArrowMovesFocus]);
/// - the focus highlight of Material widgets shown at all times, under the one ring of [TvFocusRing].
///
/// Off ([enabled] false), it hands everything down as it is. It stays in the tree when the setting changes so that the
/// widgets above the navigator keep their shape: the router would otherwise re…6676 tokens truncated…current = dropdownMenuEntries.where((e) => e.label == controller.text).firstOrNull?.value;
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
                Expanded(
                  child: Text(
                    loading
                        ? 'Loading…'
                        : onRetry != null
                        ? 'Could not load. OK to retry'
                        : text.text.isEmpty
                        ? 'Any'
                        : text.text,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
