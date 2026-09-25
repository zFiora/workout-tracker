import 'package:flutter/painting.dart';
import 'package:workout_tracker/home/exercises/models/muscle.dart';

enum BodySide { front, back }

/// Hand-authored vector body for the muscle map: an athletic male figure,
/// ~8 heads tall, arms held slightly away from the torso so every region
/// reads clearly. Defined in a 240×480 design space (x = 120 is the midline);
/// painters scale it, so it stays sharp at any size and has no background.
///
/// Front and back share one silhouette, so the two views align exactly.
/// Muscle regions are keyed by [Muscle]; a region may be several shapes
/// (e.g. quads = vastus lateralis + rectus femoris + vastus medialis +
/// adductor sweep), all highlighted together.
///
/// Left-side shapes are listed once and mirrored. Shapes are smooth closed
/// curves through the listed points (Catmull-Rom), so they stay easy to tweak.
abstract final class MuscleMapGeometry {
  static const designSize = Size(240, 480);
  static const _midX = 120.0;

  /// Neutral body parts drawn underneath the muscles (same on both sides).
  static final List<Path> silhouette = _buildSilhouette();

  static final Map<Muscle, List<Path>> _front = _buildFront();
  static final Map<Muscle, List<Path>> _back = _buildBack();

  /// Muscle regions visible from [side], in paint order.
  static Map<Muscle, List<Path>> muscles(BodySide side) =>
      side == BodySide.front ? _front : _back;

  /// Thin decorative lines drawn over the muscles.
  static List<Path> details(BodySide side) =>
      side == BodySide.front ? _frontDetails : _backDetails;

  // ── silhouette ─────────────────────────────────────────────────────────────

  static List<Path> _buildSilhouette() => [
    // Head: a plain oval — no face, so nothing competes with the muscles.
    Path()..addOval(
      Rect.fromCenter(center: const Offset(120, 36), width: 40, height: 52),
    ),
    // Neck, flaring into the traps.
    _symmetric(const [Offset(110, 54), Offset(108, 70), Offset(98, 82)]),
    // Torso: broad shoulders → lat flare → narrow waist → hips.
    _symmetric(const [
      Offset(106, 74),
      Offset(88, 82),
      Offset(76, 92),
      Offset(76, 112),
      Offset(80, 136),
      Offset(80, 160),
      Offset(84, 184),
      Offset(86, 200),
      Offset(84, 218),
      Offset(82, 236),
      Offset(92, 252),
      Offset(110, 258),
    ]),
    ..._pair(const [
      Offset(80, 86),
      Offset(64, 90),
      Offset(54, 102),
      Offset(50, 124),
      Offset(47, 150),
      Offset(45, 176),
      Offset(44, 198),
      Offset(58, 204),
      Offset(64, 180),
      Offset(70, 154),
      Offset(76, 128),
      Offset(80, 106),
    ]), // upper arms incl. shoulder caps
    ..._pair(const [
      Offset(45, 196),
      Offset(38, 222),
      Offset(34, 248),
      Offset(33, 276),
      Offset(43, 280),
      Offset(50, 254),
      Offset(56, 228),
      Offset(60, 204),
    ]), // forearms
    ..._pair(const [
      Offset(33, 274),
      Offset(30, 290),
      Offset(32, 306),
      Offset(38, 312),
      Offset(44, 304),
      Offset(45, 288),
      Offset(44, 276),
    ]), // hands
    ..._pair(const [
      Offset(84, 234),
      Offset(78, 262),
      Offset(78, 294),
      Offset(82, 326),
      Offset(88, 352),
      Offset(104, 358),
      Offset(114, 338),
      Offset(118, 300),
      Offset(119, 262),
      Offset(116, 246),
      Offset(100, 244),
    ]), // thighs
    ..._pair(const [
      Offset(88, 350),
      Offset(86, 366),
      Offset(92, 376),
      Offset(104, 376),
      Offset(108, 364),
      Offset(106, 352),
    ]), // knees
    ..._pair(const [
      Offset(88, 370),
      Offset(83, 396),
      Offset(86, 426),
      Offset(92, 452),
      Offset(102, 452),
      Offset(106, 424),
      Offset(108, 394),
      Offset(106, 370),
    ]), // lower legs
    ..._pair(const [
      Offset(91, 448),
      Offset(86, 462),
      Offset(90, 470),
      Offset(106, 470),
      Offset(108, 460),
      Offset(103, 448),
    ]), // feet
  ];

  // ── shared shapes ──────────────────────────────────────────────────────────

  static const _sideDelt = [
    Offset(70, 90),
    Offset(60, 96),
    Offset(53, 108),
    Offset(51, 124),
    Offset(56, 134),
    Offset(62, 126),
    Offset(64, 108),
  ];

  static const _forearm = [
    Offset(45, 202),
    Offset(38, 224),
    Offset(34, 250),
    Offset(34, 270),
    Offset(43, 274),
    Offset(50, 252),
    Offset(56, 228),
    Offset(60, 206),
  ];

  // ── front ──────────────────────────────────────────────────────────────────

  static Map<Muscle, List<Path>> _buildFront() => {
    Muscle.traps: _pair(const [
      Offset(109, 64),
      Offset(96, 76),
      Offset(84, 84),
      Offset(104, 84),
    ]),
    Muscle.sideDelts: _pair(_sideDelt),
    Muscle.frontDelts: _pair(const [
      Offset(84, 88),
      Offset(74, 90),
      Offset(66, 100),
      Offset(63, 116),
      Offset(66, 132),
      Offset(75, 134),
      Offset(78, 114),
      Offset(80, 98),
    ]),
    Muscle.chest: _pair(const [
      Offset(118, 92),
      Offset(104, 90),
      Offset(90, 94),
      Offset(80, 104),
      Offset(78, 120),
      Offset(84, 134),
      Offset(98, 142),
      Offset(112, 142),
      Offset(118, 136),
    ]),
    Muscle.biceps: _pair(const [
      Offset(62, 136),
      Offset(52, 142),
      Offset(49, 160),
      Offset(48, 178),
      Offset(51, 194),
      Offset(58, 198),
      Offset(64, 182),
      Offset(70, 158),
      Offset(75, 138),
    ]),
    Muscle.forearms: _pair(_forearm),
    Muscle.obliques: _pair(const [
      Offset(82, 142),
      Offset(96, 146),
      Offset(103, 152),
      Offset(103, 204),
      Offset(100, 226),
      Offset(92, 220),
      Offset(86, 200),
      Offset(84, 178),
      Offset(81, 160),
    ]),
    // Six-pack: three rows of blocks plus the lower abdominal wall.
    Muscle.abs: [
      for (final (top, bottom) in const [
        (146.0, 163.0),
        (167.0, 184.0),
        (188.0, 205.0),
      ])
        ..._rrectPair(Rect.fromLTRB(105, top, 118, bottom), 5),
      ..._pair(const [
        Offset(118, 209),
        Offset(106, 209),
        Offset(107, 226),
        Offset(114, 240),
        Offset(118, 242),
      ]),
    ],
    Muscle.quads: [
      ..._pair(const [
        // vastus lateralis (outer sweep)
        Offset(86, 252), Offset(79, 276), Offset(79, 304), Offset(83, 330),
        Offset(89, 348), Offset(95, 340), Offset(95, 300), Offset(93, 264),
      ]),
      ..._pair(const [
        // rectus femoris (centre)
        Offset(102, 254), Offset(96, 262), Offset(96, 300), Offset(98, 334),
        Offset(103, 348), Offset(108, 330), Offset(110, 294), Offset(108, 262),
      ]),
      ..._pair(const [
        // vastus medialis (teardrop)
        Offset(111, 306), Offset(107, 330), Offset(106, 348), Offset(113, 352),
        Offset(118, 336), Offset(118, 314),
      ]),
      ..._pair(const [
        // adductor sweep (inner thigh)
        Offset(110, 252), Offset(110, 280), Offset(114, 302), Offset(118, 288),
        Offset(118, 258),
      ]),
    ],
    Muscle.calves: [
      ..._pair(const [
        // lateral gastrocnemius edge
        Offset(88, 374), Offset(83, 396), Offset(86, 422), Offset(91, 432),
        Offset(95, 404), Offset(94, 380),
      ]),
      ..._pair(const [
        // medial gastrocnemius edge
        Offset(106, 374), Offset(108, 396), Offset(106, 420), Offset(101, 426),
        Offset(100, 398), Offset(101, 380),
      ]),
    ],
  };

  // ── back ───────────────────────────────────────────────────────────────────

  static Map<Muscle, List<Path>> _buildBack() => {
    Muscle.lats: _pair(const [
      Offset(80, 106),
      Offset(78, 130),
      Offset(80, 156),
      Offset(85, 180),
      Offset(92, 200),
      Offset(102, 212),
      Offset(107, 198),
      Offset(107, 172),
      Offset(104, 146),
      Offset(99, 122),
      Offset(90, 108),
    ]),
    Muscle.lowerBack: _pair(const [
      // erector columns
      Offset(118, 168), Offset(110, 174), Offset(107, 198), Offset(108, 222),
      Offset(118, 236),
    ]),
    Muscle.traps: [
      _symmetric(const [
        Offset(120, 58),
        Offset(110, 62),
        Offset(97, 78),
        Offset(82, 88),
        Offset(96, 98),
        Offset(106, 122),
        Offset(112, 148),
        Offset(120, 164),
      ]),
    ],
    Muscle.sideDelts: _pair(_sideDelt),
    Muscle.rearDelts: _pair(const [
      Offset(82, 90),
      Offset(72, 92),
      Offset(64, 102),
      Offset(63, 118),
      Offset(68, 128),
      Offset(76, 118),
      Offset(82, 102),
    ]),
    Muscle.triceps: [
      ..._pair(const [
        // lateral head
        Offset(58, 132), Offset(51, 142), Offset(48, 162), Offset(47, 182),
        Offset(52, 194), Offset(58, 186), Offset(60, 162), Offset(62, 140),
      ]),
      ..._pair(const [
        // long head
        Offset(64, 134), Offset(62, 160), Offset(62, 186), Offset(66, 196),
        Offset(72, 176), Offset(75, 150), Offset(74, 134),
      ]),
    ],
    Muscle.forearms: _pair(_forearm),
    Muscle.glutes: _pair(const [
      Offset(88, 234),
      Offset(82, 250),
      Offset(84, 270),
      Offset(96, 282),
      Offset(112, 282),
      Offset(119, 266),
      Offset(118, 244),
      Offset(106, 236),
    ]),
    Muscle.hamstrings: [
      ..._pair(const [
        // biceps femoris
        Offset(85, 290), Offset(82, 312), Offset(86, 336), Offset(94, 350),
        Offset(98, 328), Offset(97, 298),
      ]),
      ..._pair(const [
        // semitendinosus / semimembranosus
        Offset(101, 290), Offset(101, 318), Offset(104, 344), Offset(111, 344),
        Offset(116, 318), Offset(116, 292),
      ]),
    ],
    Muscle.calves: [
      ..._pair(const [
        // lateral head
        Offset(88, 372), Offset(83, 392), Offset(86, 414), Offset(94, 428),
        Offset(97, 404), Offset(96, 378),
      ]),
      ..._pair(const [
        // medial head
        Offset(100, 372), Offset(99, 402), Offset(101, 426), Offset(107, 416),
        Offset(109, 394), Offset(107, 372),
      ]),
    ],
  };

  static final List<Path> _frontDetails = [];

  static final List<Path> _backDetails = [
    Path()
      ..moveTo(120, 166)
      ..lineTo(120, 236), // spine groove between the erectors
  ];

  // ── helpers ────────────────────────────────────────────────────────────────

  static Offset _mirror(Offset p) => Offset(2 * _midX - p.dx, p.dy);

  /// The left-side shape plus its mirror image.
  static List<Path> _pair(List<Offset> left) => [
    _smooth(left),
    _smooth(left.map(_mirror).toList()),
  ];

  static List<Path> _rrectPair(Rect left, double r) {
    Path of(Rect rect) =>
        Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(r)));
    return [
      of(left),
      of(
        Rect.fromLTRB(
          2 * _midX - left.right,
          left.top,
          2 * _midX - left.left,
          left.bottom,
        ),
      ),
    ];
  }

  /// One shape spanning the midline: [leftHalf] runs from the top of the
  /// midline side down the left edge; it's closed through its mirror image.
  /// Points exactly on the midline aren't duplicated.
  static Path _symmetric(List<Offset> leftHalf) {
    final right = leftHalf.reversed
        .where((p) => p.dx != _midX)
        .map(_mirror)
        .toList();
    return _smooth([...leftHalf, ...right]);
  }

  /// Smooth closed curve through [pts] (uniform Catmull-Rom → cubic Bézier).
  static Path _smooth(List<Offset> pts) {
    final n = pts.length;
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var i = 0; i < n; i++) {
      final p0 = pts[(i - 1 + n) % n];
      final p1 = pts[i];
      final p2 = pts[(i + 1) % n];
      final p3 = pts[(i + 2) % n];
      final c1 = p1 + (p2 - p0) / 6;
      final c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    return path..close();
  }
}
