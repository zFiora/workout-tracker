import 'package:flutter/material.dart';

/// A clean "lift" decorator for [ReorderableListView] / [SliverReorderableList].
///
/// The default proxy wraps the dragged item in an opaque [Material] whose
/// background bleeds through as a gray slab — the classic "giant gray box".
/// This uses a transparent material so only the item's own card floats, plus
/// a subtle scale + shadow so the grabbed item reads as lifted off the list.
Widget liftProxyDecorator(Widget child, int index, Animation<double> animation) {
  return AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      final t = Curves.easeInOut.transform(animation.value);
      return Transform.scale(
        scale: 1 + 0.03 * t,
        child: Material(
          type: MaterialType.transparency,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28 * t),
                  blurRadius: 20 * t,
                  offset: Offset(0, 8 * t),
                ),
              ],
            ),
            child: child,
          ),
        ),
      );
    },
    child: child,
  );
}
