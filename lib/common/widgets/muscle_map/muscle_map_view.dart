import 'package:flutter/material.dart';
import 'package:workout_tracker/common/widgets/muscle_map/muscle_map_geometry.dart';
import 'package:workout_tracker/common/widgets/muscle_map/muscle_map_painter.dart';
import 'package:workout_tracker/home/exercises/models/muscle.dart';

/// Front and back body maps side by side, with [primary] muscles in the
/// theme's primary colour, [secondary] in a lighter tint of it, and the rest
/// neutral. Purely presentational — pass in any muscle sets.
class MuscleMapView extends StatelessWidget {
  const MuscleMapView({
    super.key,
    required this.primary,
    required this.secondary,
    this.backgroundColor,
    this.glow = false,
    this.showLabels = true,
  });

  final Set<Muscle> primary;
  final Set<Muscle> secondary;

  /// Soft halo behind primary muscles (see [MuscleMapPainter.glow]).
  final bool glow;

  /// "Front"/"Back" captions; hide for thumbnail-sized maps.
  final bool showLabels;

  /// The surface the map is drawn on, used for the thin separators between
  /// muscles. Defaults to the scaffold background.
  final Color? backgroundColor;

  static MuscleMapColors colorsOf(BuildContext context, {Color? background}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bg = background ?? theme.scaffoldBackgroundColor;
    // Pre-blended to opaque colours so overlapping body pieces don't show
    // darker seams where their translucent fills would stack.
    Color tint(Color c, double alpha) =>
        Color.alphaBlend(c.withValues(alpha: alpha), bg);
    return MuscleMapColors(
      body: tint(cs.onSurface, 0.07),
      neutral: tint(cs.onSurface, 0.14),
      primary: cs.primary,
      secondary: tint(cs.primary, 0.38),
      separator: bg,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context, background: backgroundColor);
    return Semantics(
      label: _semanticsLabel(),
      child: ExcludeSemantics(
        child: Row(
          children: [
            Expanded(
              child: _Side(
                side: BodySide.front,
                label: 'Front',
                map: this,
                colors: colors,
              ),
            ),
            SizedBox(width: showLabels ? 12 : 4),
            Expanded(
              child: _Side(
                side: BodySide.back,
                label: 'Back',
                map: this,
                colors: colors,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _semanticsLabel() {
    String names(Set<Muscle> s) => s.map((m) => m.displayName).join(', ');
    if (primary.isEmpty && secondary.isEmpty) {
      return 'Body map: no muscles highlighted';
    }
    return [
      'Body map.',
      if (primary.isNotEmpty) 'Primary: ${names(primary)}.',
      if (secondary.isNotEmpty) 'Secondary: ${names(secondary)}.',
    ].join(' ');
  }
}

class _Side extends StatelessWidget {
  const _Side({
    required this.side,
    required this.label,
    required this.map,
    required this.colors,
  });

  final BodySide side;
  final String label;
  final MuscleMapView map;
  final MuscleMapColors colors;

  @override
  Widget build(BuildContext context) {
    final size = MuscleMapGeometry.designSize;
    final figure = AspectRatio(
      aspectRatio: size.width / size.height,
      child: CustomPaint(
        painter: MuscleMapPainter(
          side: side,
          primary: map.primary,
          secondary: map.secondary,
          colors: colors,
          glow: map.glow,
        ),
      ),
    );
    // Sized by width in scrollables; shrinks to fit when height is bounded.
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (constraints.hasBoundedHeight) Flexible(child: figure) else figure,
          if (map.showLabels) ...[
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "● Primary  ● Secondary" key matching [MuscleMapView]'s colours.
class MuscleLegend extends StatelessWidget {
  const MuscleLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = MuscleMapView.colorsOf(context);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 20,
      runSpacing: 8,
      children: [
        _LegendItem(color: colors.primary, label: 'Primary'),
        _LegendItem(color: colors.secondary, label: 'Secondary'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  }
}
