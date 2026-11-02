import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:immich_mobile/widgets/photo_view/photo_view.dart';

/// Remote-only state; the photo widget retains ownership of its image controller.
class TvPhotoZoom extends ChangeNotifier {
  PhotoViewControllerBase? controller;
  Timer? _hold;
  bool _held = false;
  bool panning = false;
  double get factor {
    final c = controller;
    final initial = c?.scaleBoundaries?.initialScale;
    return c == null || initial == null ? 1 : (c.value.scale ?? initial) / initial;
  }

  bool get active => panning || factor > 1.001;

  void cancelHold() {
    _hold?.cancel();
    _hold = null;
  }

  void ok(KeyEvent event, VoidCallback shortPress, {VoidCallback? onActions}) {
    if (event is KeyDownEvent) {
      cancelHold();
      _held = false;
      _hold = Timer(const Duration(milliseconds: 550), () {
        _hold = null;
        _held = true;
        if (factor > 1.001) {
          panning = true;
          notifyListeners();
        } else {
          onActions?.call();
        }
      });
    } else if (event is KeyUpEvent) {
      final pending = _hold != null;
      cancelHold();
      if (!_held && pending) {
        if (panning) {
          panning = false;
          notifyListeners();
        } else {
          shortPress();
        }
      }
    }
  }

  void arrow(LogicalKeyboardKey key) {
    final c = controller;
    final bounds = c?.scaleBoundaries;
    if (c == null || bounds == null) {
      return;
    }
    var scale = c.value.scale ?? bounds.initialScale;
    var position = c.value.position;
    if (panning) {
      position += switch (key) {
        LogicalKeyboardKey.arrowLeft => const Offset(48, 0),
        LogicalKeyboardKey.arrowRight => const Offset(-48, 0),
        LogicalKeyboardKey.arrowUp => const Offset(0, 48),
        _ => const Offset(0, -48),
      };
    } else {
      final next = (scale * (key == LogicalKeyboardKey.arrowUp ? 1.25 : 0.8)).clamp(
        bounds.initialScale,
        math.min(bounds.maxScale, bounds.initialScale * 8),
      );
      position *= next / scale;
      scale = next.toDouble();
    }
    final x = math.max(0.0, (bounds.childSize.width * scale - bounds.outerSize.width) / 2);
    final y = math.max(0.0, (bounds.childSize.height * scale - bounds.outerSize.height) / 2);
    c.updateMultiple(scale: scale, position: Offset(position.dx.clamp(-x, x), position.dy.clamp(-y, y)));
    notifyListeners();
  }

  bool back() {
    cancelHold();
    if (panning) {
      panning = false;
      notifyListeners();
      return true;
    }
    if (active) {
      reset();
      return true;
    }
    return false;
  }

  void reset() {
    cancelHold();
    panning = false;
    final c = controller;
    if (c != null && c.scaleBoundaries != null) {
      c.updateMultiple(scale: c.scaleBoundaries!.initialScale, position: Offset.zero);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    cancelHold();
    super.dispose();
  }
}
