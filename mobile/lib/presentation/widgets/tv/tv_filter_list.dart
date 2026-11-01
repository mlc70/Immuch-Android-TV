import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Multi-selection list with an explicit remote cursor, including unbuilt rows.
class TvFilterList extends StatefulWidget {
  const TvFilterList({super.key, required this.labels, required this.selected, required this.onToggle});
  final List<String> labels;
  final List<bool> selected;
  final ValueChanged<int> onToggle;
  @override
  State<TvFilterList> createState() => _TvFilterListState();
}

class _TvFilterListState extends State<TvFilterList> {
  final scroll = ScrollController();
  var index = 0;
  var focused = false;
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TvFilterList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.labels.length != oldWidget.labels.length) {
      index = 0;
      if (scroll.hasClients) scroll.jumpTo(0);
    }
  }

  KeyEventResult key(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent || widget.labels.isEmpty) return KeyEventResult.ignored;
    final k = event.logicalKey;
    if (k == LogicalKeyboardKey.arrowDown || k == LogicalKeyboardKey.arrowUp) {
      if (k == LogicalKeyboardKey.arrowUp && index == 0) return KeyEventResult.ignored;
      setState(() => index = (index + (k == LogicalKeyboardKey.arrowDown ? 1 : -1)).clamp(0, widget.labels.length - 1));
      scroll.jumpTo((index * 56.0).clamp(0, scroll.position.maxScrollExtent));
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.select || k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.space) {
      widget.onToggle(index);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => Focus(
    onKeyEvent: key,
    onFocusChange: (value) => setState(() => focused = value),
    child: widget.labels.isEmpty
        ? const Center(child: Text('No matching values'))
        : ListView.builder(
            controller: scroll,
            itemExtent: 56,
            itemCount: widget.labels.length,
            itemBuilder: (context, i) => ExcludeFocus(
              child: ListTile(
                selected: focused && index == i,
                selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
                leading: Icon(widget.selected[i] ? Icons.check_box : Icons.check_box_outline_blank),
                title: Text(widget.labels[i], maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => widget.onToggle(i),
              ),
            ),
          ),
  );
}
