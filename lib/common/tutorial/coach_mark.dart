import 'package:flutter/widgets.dart';

/// One step of a coach-mark tutorial: the widget to spotlight plus the copy to
/// show beside it. Pages describe their tutorial as an ordered `List` of these,
/// referencing [GlobalKey]s attached (usually via `KeyedSubtree`) to the real
/// UI elements — nothing about the target widgets themselves has to change.
///
/// A step whose [targetKey] is not currently mounted/measurable is skipped at
/// runtime (see the overlay), so conditional or below-the-fold targets are
/// safe. Put optional/conditional steps last so the visible "x of N" numbering
/// stays contiguous.
@immutable
class CoachMarkStep {
  const CoachMarkStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.radius = 14,
    this.padding = const EdgeInsets.all(8),
  });

  /// Key attached to the widget to spotlight.
  final GlobalKey targetKey;

  /// Short heading shown in the tooltip card.
  final String title;

  /// One or two sentences explaining the feature.
  final String description;

  /// Corner radius of the spotlight cutout.
  final double radius;

  /// Extra space painted around the target inside the cutout.
  final EdgeInsets padding;
}
