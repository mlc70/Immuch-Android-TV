import 'package:flutter/material.dart';
import 'package:immich_mobile/presentation/widgets/tv/tv_photo_date_overlay.dart';

class TvPhotoDatePositionControl extends StatefulWidget {
  const TvPhotoDatePositionControl({super.key, required this.value, required this.onSave, required this.singleLine});

  final int value;
  final Future<void> Function(int) onSave;
  final bool singleLine;

  @override
  State<TvPhotoDatePositionControl> createState() => _TvPhotoDatePositionControlState();
}

class _TvPhotoDatePositionControlState extends State<TvPhotoDatePositionControl> {
  late int _value = widget.value.clamp(0, 80);
  int? _pending;
  bool _editing = false;
  bool _saving = false;
  bool _failed = false;

  @override
  void didUpdateWidget(TvPhotoDatePositionControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && !_saving && oldWidget.value != widget.value) {
      _value = widget.value.clamp(0, 80);
    }
  }

  Future<void> _save(double value) async {
    _editing = false;
    _pending = value.round();
    if (_saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    // Serialize completed adjustments so a slow older save cannot overwrite the
    // last remote key press. Capture the callback for navigation during a save.
    final save = widget.onSave;
    try {
      while (_pending != null) {
        final next = _pending!;
        _pending = null;
        await save(next);
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ListTile(title: const Text('Distance from bottom'), subtitle: Text('$_value px · Left: lower · Right: higher')),
      Slider(
        value: _value.toDouble(),
        min: 0,
        max: 80,
        divisions: 20,
        label: '$_value px',
        onChangeStart: (_) => _editing = true,
        onChanged: (value) => setState(() => _value = value.round()),
        onChangeEnd: _save,
      ),
      SizedBox(
        height: 160,
        child: ColoredBox(
          color: Colors.black,
          child: Stack(
            children: [
              TvPhotoDateOverlay(
                bottomOffset: _value,
                child: Text(
                  widget.singleLine ? 'Photo date · Photo time' : 'Photo date\nPhoto time',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
      if (_saving) const Text('Saving position…'),
      if (_failed)
        TextButton(onPressed: () => _save(_value.toDouble()), child: const Text('Could not save position · Retry')),
    ],
  );
}
