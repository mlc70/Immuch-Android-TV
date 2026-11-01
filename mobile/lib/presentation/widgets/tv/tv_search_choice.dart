import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A bounded remote list. An explicit cursor also reaches off-screen lazy rows.
Future<T?> showTvSearchChoice<T>({
  required BuildContext context,
  required Widget title,
  required List<DropdownMenuEntry<T>> entries,
  T? current,
}) => showDialog<T>(
  context: context,
  barrierDismissible: false,
  traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
  builder: (_) => _Choice<T>(title: title, entries: entries.where((e) => e.enabled).toList(), current: current),
);

class _Choice<T> extends StatefulWidget {
  const _Choice({required this.title, required this.entries, this.current});
  final Widget title;
  final List<DropdownMenuEntry<T>> entries;
  final T? current;
  @override
  State<_Choice<T>> createState() => _ChoiceState<T>();
}

class _ChoiceState<T> extends State<_Choice<T>> {
  late int index = widget.entries
      .indexWhere((e) => e.value == widget.current)
      .clamp(0, widget.entries.isEmpty ? 0 : widget.entries.length - 1);
  late final scroll = ScrollController(initialScrollOffset: index * 56.0);
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  KeyEventResult key(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) {
      return KeyEventResult.ignored;
    }
    final k = event.logicalKey;
    if (k == LogicalKeyboardKey.escape || k == LogicalKeyboardKey.goBack) {
      Navigator.of(context).pop();
    } else if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.select || k == LogicalKeyboardKey.space) {
      if (widget.entries.isNotEmpty) {
        Navigator.of(context).pop(widget.entries[index].value);
      }
    } else if (k == LogicalKeyboardKey.arrowDown || k == LogicalKeyboardKey.arrowUp) {
      if (widget.entries.isNotEmpty) {
        setState(
          () => index = (index + (k == LogicalKeyboardKey.arrowDown ? 1 : -1)).clamp(0, widget.entries.length - 1),
        );
        scroll.jumpTo((index * 56.0).clamp(0, scroll.position.maxScrollExtent));
      }
    } else if (k != LogicalKeyboardKey.arrowLeft && k != LogicalKeyboardKey.arrowRight) {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => Dialog(
    child: SizedBox(
      width: 560,
      height: 380,
      child: Focus(
        autofocus: true,
        onKeyEvent: key,
        child: Column(
          children: [
            Padding(padding: const EdgeInsets.all(16), child: widget.title),
            const Text('Up / Down: choose    OK: select    Back: cancel'),
            Expanded(
              child: widget.entries.isEmpty
                  ? const Center(child: Text('No matching values'))
                  : ListView.builder(
                      controller: scroll,
                      itemExtent: 56,
                      itemCount: widget.entries.length,
                      itemBuilder: (context, i) => ExcludeFocus(
                        child: ListTile(
                          selected: i == index,
                          selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
                          leading: Icon(i == index ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                          title: Text(widget.entries[i].label, maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () => Navigator.of(context).pop(widget.entries[i].value),
                        ),
                      ),
                    ),
            ),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back')),
          ],
        ),
      ),
    ),
  );
}
