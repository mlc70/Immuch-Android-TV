import 'package:flutter/material.dart';

/// Owns the scope node for the whole route lifetime, including exit animation.
class TvModalScope extends StatefulWidget {
  const TvModalScope({super.key, required this.child});
  final Widget child;
  @override
  State<TvModalScope> createState() => _TvModalScopeState();
}

class _TvModalScopeState extends State<TvModalScope> {
  final node = FocusScopeNode(
    traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
    directionalTraversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
  );
  @override
  void dispose() {
    node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FocusScope(node: node, child: widget.child);
}
