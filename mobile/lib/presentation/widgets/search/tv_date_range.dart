import 'package:flutter/material.dart';
import 'package:immich_mobile/presentation/widgets/tv/tv_search_choice.dart';

/// Draft dates stay local until Apply; Back never changes the active query.
class TvDateRange extends StatefulWidget {
  const TvDateRange({super.key, required this.start, required this.end, required this.onChanged});
  final DateTime start;
  final DateTime end;
  final void Function(DateTime, DateTime) onChanged;
  @override
  State<TvDateRange> createState() => _TvDateRangeState();
}

class _TvDateRangeState extends State<TvDateRange> {
  late DateTime start = widget.start;
  late DateTime end = widget.end;

  Future<void> choose(bool first, int part) async {
    final date = first ? start : end;
    final now = DateTime.now();
    final max = part == 0
        ? now.year
        : part == 1
        ? 12
        : DateUtils.getDaysInMonth(date.year, date.month);
    final min = part == 0 ? 1900 : 1;
    final values = [for (int i = max; i >= min; i--) i];
    final chosen = await showTvSearchChoice<int>(
      context: context,
      title: Text('${first ? 'Start' : 'End'} ${['year', 'month', 'day'][part]}'),
      entries: [for (final v in values) DropdownMenuEntry(value: v, label: '$v')],
      current: part == 0
          ? date.year
          : part == 1
          ? date.month
          : date.day,
    );
    if (chosen == null || !mounted) {
      return;
    }
    final year = part == 0 ? chosen : date.year;
    final month = part == 1 ? chosen : date.month;
    final day = (part == 2 ? chosen : date.day).clamp(1, DateUtils.getDaysInMonth(year, month));
    var next = DateTime(year, month, day);
    final today = DateUtils.dateOnly(now);
    if (next.isAfter(today)) {
      next = today;
    }
    setState(() {
      if (first) {
        start = next;
        if (end.isBefore(start)) {
          end = start;
        }
      } else {
        end = next;
        if (start.isAfter(end)) {
          start = end;
        }
      }
    });
    widget.onChanged(start, end);
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final first in [true, false]) ...[
          Text(first ? 'Start date' : 'End date'),
          for (var part = 0; part < 3; part++)
            OutlinedButton(
              key: ValueKey('${first ? 'start' : 'end'}_$part'),
              onPressed: () => choose(first, part),
              child: Text(
                '${['Year', 'Month', 'Day'][part]}: ${part == 0
                    ? (first ? start : end).year
                    : part == 1
                    ? (first ? start : end).month
                    : (first ? start : end).day}',
              ),
            ),
        ],
      ],
    ),
  );
}
