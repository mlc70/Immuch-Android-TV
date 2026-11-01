import 'package:flutter/material.dart';
import 'package:immich_mobile/constants/enums.dart';
import 'package:immich_mobile/generated/translations.g.dart';
import 'package:immich_mobile/presentation/widgets/tv/tv_search_choice.dart';

Future<TextSearchType?> showTvTextSearchMode({
  required BuildContext context,
  required TextSearchType current,
  required bool smartSearch,
  required bool ocr,
}) => showTvSearchChoice<TextSearchType>(
  context: context,
  title: Text(context.t.show_text_search_menu),
  current: current,
  entries: [
    if (smartSearch) DropdownMenuEntry(value: TextSearchType.context, label: context.t.search_by_context),
    DropdownMenuEntry(value: TextSearchType.filename, label: context.t.search_filter_filename),
    DropdownMenuEntry(value: TextSearchType.description, label: context.t.search_by_description),
    if (ocr) DropdownMenuEntry(value: TextSearchType.ocr, label: context.t.search_by_ocr),
  ],
);
