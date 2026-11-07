import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TvPhotoAction {
  const TvPhotoAction(this.label, this.run, {this.emphasized = false});
  final bool emphasized;
  final String label;
  final FutureOr<void> Function()? run;
}

/// Modal route owns remote focus; the photograph beneath retains its size.
Future<void> showTvPhotoActions({
  required BuildContext context,
  required Future<List<TvPhotoAction>> Function() details,
  required Future<List<TvPhotoAction>> Function() albums,
  required Future<List<TvPhotoAction>> Function() tags,
  Future<List<TvPhotoAction>> Function()? rating,
  Future<List<TvPhotoAction>> Function()? location,
  required VoidCallback rotate,
  required Future<void> Function()? favorite,
  required bool isFavorite,
}) => showGeneralDialog<void>(
  context: context,
  barrierDismissible: false,
  barrierLabel: 'Photo Actions',
  barrierColor: Colors.black26,
  transitionDuration: const Duration(milliseconds: 180),
  pageBuilder: (context, _, _) => Align(
    alignment: Alignment.centerRight,
    child: SizedBox(
      width: math.min(440, MediaQuery.sizeOf(context).width * 0.48),
      height: double.infinity,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        elevation: 12,
        child: SafeArea(
          child: TvPhotoActions(
            details: details,
            albums: albums,
            tags: tags,
            rating: rating,
            location: location,
            rotate: rotate,
            favorite: favorite,
            isFavorite: isFavorite,
          ),
        ),
      ),
    ),
  ),
);

class TvPhotoActions extends StatefulWidget {
  const TvPhotoActions({
    super.key,
    required this.details,
    required this.albums,
    required this.tags,
    this.rating,
    this.location,
    required this.rotate,
    required this.favorite,
    required this.isFavorite,
  });
  final Future<List<TvPhotoAction>> Function() details;
  final Future<List<TvPhotoAction>> Function() albums;
  final Future<List<TvPhotoAction>> Function() tags;
  final Future<List<TvPhotoAction>> Function()? rating;
  final Future<List<TvPhotoAction>> Function()? location;
  final VoidCallback rotate;
  final Future<void> Function()? favorite;
  final bool isFavorite;
  @override
  State<TvPhotoActions> createState() => _TvPhotoActionsState();
}

class _TvPhotoActionsState extends State<TvPhotoActions> {
  final _scroll = ScrollController();
  String _title = 'Photo Actions';
  String _message = '';
  List<TvPhotoAction>? _submenu;
  Future<List<TvPhotoAction>> Function()? _reload;
  int _index = 0;
  bool _busy = false;
  bool _consumeOpeningRelease = true;
  late bool _favorite = widget.isFavorite;
  String _query = '';

  List<TvPhotoAction> get _rows =>
      (_submenu == null
          ? null
          : _submenu!
                .where(
                  (r) =>
                      r.label.toLowerCase().contains(_query.toLowerCase()) ||
                      r.label == 'Back to Photo Actions',
                )
                .toList()) ??
      [
        TvPhotoAction('Details', () => _load('Details', widget.details)),
        TvPhotoAction('Rotate clockwise (display only)', widget.rotate),
        TvPhotoAction(
          'Add to Album',
          widget.favorite == null
              ? null
              : () => _load('Add to Album', widget.albums),
        ),
        TvPhotoAction(
          'Tags',
          widget.favorite == null ? null : () => _load('Tags', widget.tags),
        ),
        TvPhotoAction(
          _favorite ? 'Remove from Favorites' : 'Add to Favorites',
          widget.favorite == null
              ? null
              : () async {
                  await widget.favorite!();
                  if (mounted) {
                    setState(() => _favorite = !_favorite);
                  }
                },
        ),
        TvPhotoAction(
          'Star Rating',
          widget.rating == null
              ? null
              : () => _load('Star Rating', widget.rating!),
        ),
        TvPhotoAction(
          'Add / Change Location',
          widget.location == null
              ? null
              : () => _load('Location', widget.location!),
        ),
        TvPhotoAction('Close', () => Navigator.of(context).pop()),
      ];

  Future<void> _load(
    String title,
    Future<List<TvPhotoAction>> Function() loader,
  ) async {
    final rows = await loader();
    if (!mounted) {
      return;
    }
    setState(() {
      _title = title;
      _query = '';
      _reload = title == 'Location' ? null : loader;
      _submenu = [...rows, TvPhotoAction('Back to Photo Actions', _back)];
      _index = 0;
    });
    if (_scroll.hasClients) {
      _scroll.jumpTo(0);
    }
  }

  void _back() {
    if (_submenu == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _submenu = null;
        _query = '';
        _reload = null;
        _index = 0;
        _title = 'Photo Actions';
        _message = '';
      });
      if (_scroll.hasClients) {
        _scroll.jumpTo(0);
      }
    }
  }

  Future<void> _activate() async {
    if (_busy || _rows.isEmpty) {
      return;
    }
    final row = _rows[_index];
    final reload = _reload;
    final selected = _index;
    if (row.run == null) {
      return;
    }
    setState(() {
      _busy = true;
      _message = 'Working…';
    });
    try {
      await row.run!();
      if (mounted && reload != null && identical(reload, _reload)) {
        final rows = await reload();
        if (mounted) {
          setState(() {
            _submenu = [...rows, TvPhotoAction('Back to Photo Actions', _back)];
            _index = selected.clamp(0, _rows.length - 1);
          });
        }
      }
      if (mounted) {
        setState(() => _message = 'Done');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'Could not complete action. Check connection / permissions and press OK to retry.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    // A dialog can receive the release/repeats of the OK that opened it.
    if (event is KeyDownEvent) {
      _consumeOpeningRelease = false;
    }
    if (event is KeyUpEvent) {
      _consumeOpeningRelease = false;
      return KeyEventResult.handled;
    }
    if (_consumeOpeningRelease) {
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.goBack) {
      if (!_busy && event is KeyDownEvent) {
        _back();
      }
    } else if (key == LogicalKeyboardKey.arrowLeft &&
        (_title == 'Tags' || _title == 'Add to Album')) {
      if (!_busy && event is KeyDownEvent) {
        unawaited(_search());
      }
    } else if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown) {
      if (!_busy) {
        setState(
          () =>
              _index = (_index + (key == LogicalKeyboardKey.arrowDown ? 1 : -1))
                  .clamp(0, _rows.length - 1),
        );
        if (_scroll.hasClients) {
          _scroll.jumpTo(
            (_index * 64.0).clamp(0, _scroll.position.maxScrollExtent),
          );
        }
      }
    } else if (event is KeyDownEvent &&
        (key == LogicalKeyboardKey.select ||
            key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter ||
            key == LogicalKeyboardKey.gameButtonA ||
            key == LogicalKeyboardKey.space)) {
      unawaited(_activate());
    }
    return KeyEventResult.handled;
  }

  Future<void> _search() async {
    final value = await tvPhotoTextInput(
      context,
      'Search $_title',
      initial: _query,
    );
    if (mounted && value != null) {
      setState(() {
        _query = value;
        _index = 0;
      });
      if (_scroll.hasClients) {
        _scroll.jumpTo(0);
      }
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _submenu == null && !_busy,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && !_busy) {
        _back();
      }
    },
    child: Focus(
      autofocus: true,
      onKeyEvent: _key,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_title, style: Theme.of(context).textTheme.headlineSmall),
            const Text('Up / Down: choose · OK: select · Back: return'),
            if (_title == 'Tags' || _title == 'Add to Album')
              ExcludeFocus(
                child: TextButton(
                  onPressed: _busy ? null : _search,
                  child: Text(
                    'Search · Left to type${_query.isEmpty ? '' : ': $_query'}',
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                itemCount: _rows.length,
                itemExtent: 64,
                itemBuilder: (context, i) => ExcludeFocus(
                  child: ListTile(
                    selected: i == _index,
                    selectedTileColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    title: Text(
                      _rows[i].label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: _rows[i].emphasized
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    textColor: _rows[i].run == null
                        ? Theme.of(context).disabledColor
                        : null,
                    onTap: _busy
                        ? null
                        : () {
                            setState(() => _index = i);
                            unawaited(_activate());
                          },
                  ),
                ),
              ),
            ),
            if (_busy) const LinearProgressIndicator(),
            Text(_message, maxLines: 3),
          ],
        ),
      ),
    ),
  );
}

Future<String?> tvPhotoTextInput(
  BuildContext context,
  String title, {
  String initial = '',
}) async {
  return showDialog<String>(
    context: context,
    builder: (context) => _TvPhotoTextInput(title: title, initial: initial),
  );
}

class _TvPhotoTextInput extends StatefulWidget {
  const _TvPhotoTextInput({required this.title, required this.initial});
  final String title;
  final String initial;
  @override
  State<_TvPhotoTextInput> createState() => _TvPhotoTextInputState();
}

class _TvPhotoTextInputState extends State<_TvPhotoTextInput> {
  late final _controller = TextEditingController(text: widget.initial);
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: _controller,
      autofocus: true,
      textInputAction: TextInputAction.search,
      onSubmitted: (value) => Navigator.of(context).pop(value),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      TextButton(
        onPressed: () => Navigator.of(context).pop(_controller.text),
        child: const Text('Search'),
      ),
    ],
  );
}
