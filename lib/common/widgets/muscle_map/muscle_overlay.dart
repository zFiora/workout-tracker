import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:workout_tracker/common/widgets/muscle_map/muscle_map_geometry.dart';
import 'package:workout_tracker/common/widgets/muscle_map/muscle_map_painter.dart';
import 'package:workout_tracker/home/exercises/models/muscle.dart';

/// Which figure(s) to lay over a photo; [none] hides the overlay.
enum OverlayView { front, back, both, none }

/// Pure layout maths shared by the photo preview, the overlay editor and the
/// exported image, so all three place the overlay (and crop the photo)
/// identically.
abstract final class MuscleOverlayLayout {
  /// Progress photos are shown, edited and exported in a 4:5 portrait frame.
  static const photoAspect = 4 / 5;

  /// The part of an [image] to draw into a [target] box so it fills the box
  /// without distortion (BoxFit.cover): centred, cropping only the overflow.
  static Rect coverSourceRect(Size image, Size target) {
    if (image.isEmpty || target.isEmpty) return Offset.zero & image;
    final imageAspect = image.width / image.height;
    final targetAspect = target.width / target.height;
    if (imageAspect > targetAspect) {
      final w = image.height * targetAspect; // too wide: crop the sides
      return Rect.fromLTWH((image.width - w) / 2, 0, w, image.height);
    }
    final h = image.width / targetAspect; // too tall: crop top/bottom
    return Rect.fromLTWH(0, (image.height - h) / 2, image.width, h);
  }

  /// Default (untransformed) placement of each figure inside a [box]:
  /// bottom-aligned, up to 88% of the box height, side by side for
  /// [OverlayView.both], keeping the figures' own aspect ratio.
  static List<Rect> figureRects(Size box, OverlayView view) {
    if (view == OverlayView.none) return const [];
    const design = MuscleMapGeometry.designSize;
    final count = view == OverlayView.both ? 2 : 1;
    final gap = box.width * 0.02;
    final maxH = box.height * 0.88;
    final maxW = (box.width * 0.94 - gap * (count - 1)) / count;
    final scale = math.min(maxH / design.height, maxW / design.width);
    final w = design.width * scale;
    final h = design.height * scale;
    final totalW = w * count + gap * (count - 1);
    final left = (box.width - totalW) / 2;
    final top = box.height - h - box.height * 0.04;
    return [
      for (var i = 0; i < count; i++)
        Rect.fromLTWH(left + i * (w + gap), top, w, h),
    ];
  }

  /// Centre of the default placement — the pivot the user's transform
  /// rotates/scales around.
  static Offset anchor(Size box, OverlayView view) {
    final rects = figureRects(box, view);
    if (rects.isEmpty) return box.center(Offset.zero);
    return rects.reduce((a, b) => a.expandToInclude(b)).center;
  }

  static List<BodySide> sides(OverlayView view) => switch (view) {
    OverlayView.front => const [BodySide.front],
    OverlayView.back => const [BodySide.back],
    OverlayView.both => const [BodySide.front, BodySide.back],
    OverlayView.none => const [],
  };
}

/// The user's placement of the overlay on top of the default layout.
///
/// Resolution-independent: [offset] is a fraction of the photo frame's
/// width/height, so the same transform reproduces exactly in the small
/// preview, the full-screen editor and the 1080-px export.
@immutable
class OverlayTransform {
  const OverlayTransform({
    this.offset = Offset.zero,
    this.scale = 1,
    this.rotation = 0,
  });

  static const identity = OverlayTransform();
  static const minScale = 0.35;
  static const maxScale = 3.0;

  /// Rotations within this of upright snap to 0 while gesturing.
  static const rotationSnap = 4 * math.pi / 180;

  /// The overlay's centre may not leave this inset of the frame, so it can
  /// never be lost off-screen.
  static const centerInset = 0.05;

  final Offset offset;
  final double scale;
  final double rotation;

  bool get isIdentity => offset == Offset.zero && scale == 1 && rotation == 0;

  /// Result of a drag/pinch/rotate gesture that began at [start]:
  /// [translation] is the focal-point movement in pixels of a [frame]-sized
  /// box, [scaleFactor]/[rotationDelta] are relative to the gesture start.
  /// Clamped to sensible bounds.
  factory OverlayTransform.fromGesture(
    OverlayTransform start, {
    required Size frame,
    required OverlayView view,
    Offset translation = Offset.zero,
    double scaleFactor = 1,
    double rotationDelta = 0,
  }) {
    var rotation = _normalizeAngle(start.rotation + rotationDelta);
    if (rotation.abs() < rotationSnap) rotation = 0;
    return OverlayTransform(
      offset:
          start.offset +
          Offset(translation.dx / frame.width, translation.dy / frame.height),
      scale: start.scale * scaleFactor,
      rotation: rotation,
    ).clamped(frame, view);
  }

  /// Keeps scale within [minScale]..[maxScale] and the overlay's centre
  /// inside the frame (minus [centerInset]).
  OverlayTransform clamped(Size frame, OverlayView view) {
    final anchor = MuscleOverlayLayout.anchor(frame, view);
    final center =
        anchor + Offset(offset.dx * frame.width, offset.dy * frame.height);
    final clampedCenter = Offset(
      center.dx.clamp(
        frame.width * centerInset,
        frame.width * (1 - centerInset),
      ),
      center.dy.clamp(
        frame.height * centerInset,
        frame.height * (1 - centerInset),
      ),
    );
    final d = clampedCenter - anchor;
    return OverlayTransform(
      offset: Offset(d.dx / frame.width, d.dy / frame.height),
      scale: scale.clamp(minScale, maxScale),
      rotation: rotation,
    );
  }

  /// Applies this transform to [canvas] for a [frame]-sized box: translate
  /// by [offset], then rotate/scale around the default placement's centre.
  void applyTo(Canvas canvas, Size frame, OverlayView view) {
    final pivot = MuscleOverlayLayout.anchor(frame, view);
    canvas
      ..translate(
        pivot.dx + offset.dx * frame.width,
        pivot.dy + offset.dy * frame.height,
      )
      ..rotate(rotation)
      ..scale(scale)
      ..translate(-pivot.dx, -pivot.dy);
  }

  Map<String, dynamic> toJson() => {
    'dx': offset.dx,
    'dy': offset.dy,
    'scale': scale,
    'rotation': rotation,
  };

  factory OverlayTransform.fromJson(Map<String, dynamic>? json) {
    if (json == null) return identity;
    double read(String k, double fallback) {
      final v = (json[k] as num?)?.toDouble();
      return v == null || !v.isFinite ? fallback : v;
    }

    return OverlayTransform(
      offset: Offset(read('dx', 0), read('dy', 0)),
      scale: read('scale', 1).clamp(minScale, maxScale),
      rotation: _normalizeAngle(read('rotation', 0)),
    );
  }

  static double _normalizeAngle(double a) {
    // Leave in-range angles untouched so they round-trip exactly.
    if (a > -math.pi && a <= math.pi) return a;
    var r = a % (2 * math.pi);
    if (r > math.pi) r -= 2 * math.pi;
    if (r < -math.pi) r += 2 * math.pi;
    return r;
  }

  @override
  bool operator ==(Object other) =>
      other is OverlayTransform &&
      other.offset == offset &&
      other.scale == scale &&
      other.rotation == rotation;

  @override
  int get hashCode => Object.hash(offset, scale, rotation);

  @override
  String toString() => 'OverlayTransform($offset, x$scale, ${rotation}rad)';
}

/// Everything about how the overlay sits on a progress photo; persisted with
/// the workout's recap so the composition can be reopened and edited.
@immutable
class OverlayConfig {
  const OverlayConfig({
    this.view = OverlayView.both,
    this.transform = OverlayTransform.identity,
    this.opacity = defaultOpacity,
  });

  static const defaults = OverlayConfig();
  static const defaultOpacity = 0.8;
  static const minOpacity = 0.15;

  final OverlayView view;
  final OverlayTransform transform;
  final double opacity;

  bool get visible => view != OverlayView.none && opacity > 0;

  OverlayConfig copyWith({
    OverlayView? view,
    OverlayTransform? transform,
    double? opacity,
  }) => OverlayConfig(
    view: view ?? this.view,
    transform: transform ?? this.transform,
    opacity: opacity ?? this.opacity,
  );

  Map<String, dynamic> toJson() => {
    'view': view.name,
    'transform': transform.toJson(),
    'opacity': opacity,
  };

  factory OverlayConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return defaults;
    final opacity = (json['opacity'] as num?)?.toDouble();
    return OverlayConfig(
      view: OverlayView.values.asNameMap()[json['view']] ?? OverlayView.both,
      transform: OverlayTransform.fromJson(
        json['transform'] == null
            ? null
            : Map<String, dynamic>.from(json['transform'] as Map),
      ),
      opacity: opacity == null || !opacity.isFinite
          ? defaultOpacity
          : opacity.clamp(minOpacity, 1.0),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is OverlayConfig &&
      other.view == view &&
      other.transform == transform &&
      other.opacity == opacity;

  @override
  int get hashCode => Object.hash(view, transform, opacity);
}

/// Paints the worked-muscle figures on a transparent background, sized to a
/// photo frame and placed by [transform]. [opacity] fades the whole overlay
/// as one layer, so regions stay crisp and evenly transparent. Reuses
/// [MuscleMapPainter] for the shapes.
class MuscleOverlayPainter extends CustomPainter {
  MuscleOverlayPainter({
    required this.primary,
    required this.secondary,
    required this.opacity,
    this.view = OverlayView.both,
    this.transform = OverlayTransform.identity,
    this.colors = MuscleMapColors.overlay,
  });

  final Set<Muscle> primary;
  final Set<Muscle> secondary;
  final double opacity;
  final OverlayView view;
  final OverlayTransform transform;
  final MuscleMapColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0 || view == OverlayView.none) return;
    final rects = MuscleOverlayLayout.figureRects(size, view);
    final sides = MuscleOverlayLayout.sides(view);
    canvas.saveLayer(
      Offset.zero & size,
      Paint()..color = Color.fromRGBO(0, 0, 0, opacity.clamp(0.0, 1.0)),
    );
    transform.applyTo(canvas, size, view);
    for (var i = 0; i < rects.length; i++) {
      canvas
        ..save()
        ..translate(rects[i].left, rects[i].top);
      MuscleMapPainter(
        side: sides[i],
        primary: primary,
        secondary: secondary,
        colors: colors,
        glow: true,
      ).paint(canvas, rects[i].size);
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(MuscleOverlayPainter old) =>
      old.opacity != opacity ||
      old.view != view ||
      old.transform != transform ||
      old.colors != colors ||
      !_same(old.primary, primary) ||
      !_same(old.secondary, secondary);

  static bool _same(Set<Muscle> a, Set<Muscle> b) =>
      a.length == b.length && a.containsAll(b);
}

/// Widget form of [MuscleOverlayPainter]: fills its parent (put it in a
/// `Stack` over the photo) and is transparent everywhere except the figures.
class MuscleOverlay extends StatelessWidget {
  const MuscleOverlay({
    super.key,
    required this.primary,
    required this.secondary,
    required this.config,
  });

  final Set<Muscle> primary;
  final Set<Muscle> secondary;
  final OverlayConfig config;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      size: Size.infinite,
      painter: MuscleOverlayPainter(
        primary: primary,
        secondary: secondary,
        opacity: config.opacity,
        view: config.view,
        transform: config.transform,
      ),
    ),
  );
}

/// Soft bottom darkening drawn over the photo whenever the overlay is shown,
/// so the figures stay readable on bright photos. The export draws the same
/// gradient ([scrimColors]/[scrimStops]) so preview, editor and image match.
class PhotoOverlayScrim extends StatelessWidget {
  const PhotoOverlayScrim({super.key});

  static const scrimColors = [Color(0x00000000), Color(0x99000000)];
  static const scrimStops = [0.45, 1.0];

  @override
  Widget build(BuildContext context) => const IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: scrimColors,
          stops: scrimStops,
        ),
      ),
    ),
  );
}
