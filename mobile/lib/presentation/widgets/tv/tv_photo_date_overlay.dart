import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The chosen bottom distance is exact, independent of TV overscan padding.
class TvPhotoDateOverlay extends StatelessWidget {
  const TvPhotoDateOverlay({super.key, required this.bottomOffset, required this.child});

  final int bottomOffset;
  final Widget child;

  @override
  Widget build(BuildContext context) => Positioned(
    left: math.max(16, MediaQuery.paddingOf(context).left),
    bottom: bottomOffset.clamp(0, 80).toDouble(),
    child: IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: child),
      ),
    ),
  );
}
