import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:workout_tracker/common/widgets/muscle_map/muscle_map_geometry.dart';
import 'package:workout_tracker/home/exercises/models/muscle.dart';

enum MuscleHighlight { primary, secondary, none }

/// How [muscle] should be drawn. Primary wins if a muscle is in both sets.
MuscleHighlight muscleHighlight(
  Muscle muscle, {
  required Set<Muscle> primary,
  required Set<Muscle> secondary,
}) {
  if (primary.contains(muscle)) return MuscleHighlight.primary;
  if (secondary.contains(muscle)) return MuscleHighlight.secondary;
  return MuscleHighlight.none;
}

/// Colours for the body map; resolved from the theme by `MuscleMapView`.
@immutable
class MuscleMapColors {
  const MuscleMapColors({
    required this.body,
    required this.neutral,
    required this.primary,
    required this.secondary,
    required this.separator,
  });

  /// Non-muscle parts (head, hands, knees, feet, gaps between muscles).
  final Color body;

  /// Muscles that weren't worked.
  final Color neutral;
  final Color primary;
  final Color secondary;

  /// Outline between adjacent regions — the surface the map sits on.
  final Color separator;

  /// Palette for drawing the map *on top of a photo*. All colours are
  /// opaque on purpose: the overlay's transparency is applied once to the
  /// whole layer (see `MuscleOverlayPainter`), so overlapping body pieces
  /// don't stack into darker seams and every region fades evenly.
  static const overlay = MuscleMapColors(
    body: Color(0xFF1A2236),
    neutral: Color(0xFF3A4560),
    primary: Color(0xFF4D8DFF),
    secondary: Color(0xFF9DBEFF),
    separator: Color(0xFF05070C),
  );

  @override
  bool operator ==(Object other) =>
      other is MuscleMapColors &&
      other.body == body &&
      other.neutral == neutral &&
      other.primary == primary &&
      other.secondary == secondary &&
      other.separator == separator;

  @override
  int get hashCode => Object.hash(body, neutral, primary, secondary, separator);
}

/// Paints one side of the stylised body with muscles coloured by
/// [MuscleHighlight]. All shapes come from [MuscleMapGeometry].
class MuscleMapPainter extends CustomPainter {
  MuscleMapPainter({
    required this.side,
    required this.primary,
    required this.secondary,
    required this.colors,
    this.glow = false,
  });

  final BodySide side;
  final Set<Muscle> primary;
  final Set<Muscle> secondary;
  final MuscleMapColors colors;

  /// Soft halo behind primary muscles, for emphasis on dark backgrounds.
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    const design = MuscleMapGeometry.designSize;
    final scale = math.min(
      size.width / design.width,
      size.height / design.height,
    );
    canvas
      ..save()
      ..translate(
        (size.width - design.width * scale) / 2,
        (size.height - design.height * scale) / 2,
      )
      ..scale(scale);

    final fill = Paint()..style = PaintingStyle.fill;
    final separator = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeJoin = StrokeJoin.round
      ..color = colors.separator;

    fill.color = colors.body;
    for (final path in MuscleMapGeometry.silhouette) {
      canvas.drawPath(path, fill);
    }

    if (glow && primary.isNotEmpty) {
      final halo = Paint()
        ..style = PaintingStyle.fill
        ..color = colors.primary.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
      MuscleMapGeometry.muscles(side).forEach((muscle, paths) {
        if (!primary.contains(muscle)) return;
        for (final path in paths) {
          canvas.drawPath(path, halo);
        }
      });
    }

    MuscleMapGeometry.muscles(side).forEach((muscle, paths) {
      fill.color = switch (muscleHighlight(
        muscle,
        primary: primary,
        secondary: secondary,
      )) {
        MuscleHighlight.primary => colors.primary,
        MuscleHighlight.secondary => colors.secondary,
        MuscleHighlight.none => colors.neutral,
      };
      for (final path in paths) {
        canvas
          ..drawPath(path, fill)
          ..drawPath(path, separator);
      }
    });

    final detail = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..color = colors.separator.withValues(alpha: 0.7);
    for (final path in MuscleMapGeometry.details(side)) {
      canvas.drawPath(path, detail);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(MuscleMapPainter old) =>
      old.side != side ||
      old.colors != colors ||
      old.glow != glow ||
      !_setEquals(old.primary, primary) ||
      !_setEquals(old.secondary, secondary);

  static bool _setEquals(Set<Muscle> a, Set<Muscle> b) =>
      a.length == b.length && a.containsAll(b);
}
