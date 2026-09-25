// Overlay layout, export data preparation and image rendering.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/common/units/weight_unit.dart';
import 'package:workout_tracker/common/widgets/muscle_map/muscle_map_geometry.dart';
import 'package:workout_tracker/common/widgets/muscle_map/muscle_overlay.dart';
import 'package:workout_tracker/home/exercises/models/muscle.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';
import 'package:workout_tracker/home/session/recap/recap_export.dart';
import 'package:workout_tracker/home/session/services/muscle_summary_service.dart';

final _t = DateTime(2026, 9, 25, 18, 30); // a Friday

WorkoutHistoryEntry _entry({String name = 'Push Day'}) => WorkoutHistoryEntry(
  id: 'w1',
  templateId: 't',
  templateName: name,
  templateIcon: '',
  startedAt: _t,
  endedAt: _t.add(const Duration(minutes: 45)),
  duration: const Duration(minutes: 45),
  logs: [
    ExerciseLog(
      exerciseId: 3,
      exerciseName: 'Bench',
      exerciseIcon: '',
      sets: [
        PerformedSet(weight: 100, reps: 5, timestamp: _t),
        PerformedSet(weight: 100, reps: 5, timestamp: _t),
      ],
    ),
  ],
);

const _summary = MuscleSummary(
  primary: {Muscle.triceps, Muscle.chest}, // unordered on purpose
  secondary: {Muscle.frontDelts},
  setsPerMuscle: {},
  unrecognizedExercises: [],
);

Size _pngSize(Uint8List png) {
  // PNG IHDR: width/height are big-endian u32 at bytes 16..24.
  final d = ByteData.sublistView(png);
  return Size(d.getUint32(16).toDouble(), d.getUint32(20).toDouble());
}

/// A point well inside the left pec in the 240×480 design space.
const kChestDesignPoint = Offset(98, 118);

void main() {
  group('MuscleOverlayLayout.coverSourceRect (no distortion)', () {
    test('a wide image is cropped at the sides, keeping the target aspect', () {
      final r = MuscleOverlayLayout.coverSourceRect(
        const Size(4000, 3000),
        const Size(400, 500),
      );
      expect(r.height, 3000);
      expect(r.width / r.height, closeTo(400 / 500, 1e-9));
      expect(r.left, closeTo((4000 - r.width) / 2, 1e-9)); // centred
      expect(r.top, 0);
    });

    test('a tall image is cropped top and bottom', () {
      final r = MuscleOverlayLayout.coverSourceRect(
        const Size(1000, 3000),
        const Size(400, 500),
      );
      expect(r.width, 1000);
      expect(r.width / r.height, closeTo(0.8, 1e-9));
      expect(r.top, closeTo((3000 - r.height) / 2, 1e-9));
    });

    test('a matching aspect uses the whole image', () {
      final r = MuscleOverlayLayout.coverSourceRect(
        const Size(800, 1000),
        const Size(400, 500),
      );
      expect(r, const Rect.fromLTWH(0, 0, 800, 1000));
    });
  });

  group('MuscleOverlayLayout.figureRects', () {
    const box = Size(400, 500);
    final aspect =
        MuscleMapGeometry.designSize.width /
        MuscleMapGeometry.designSize.height;

    for (final view in [
      OverlayView.front,
      OverlayView.back,
      OverlayView.both,
    ]) {
      test(
        '$view: inside the box, figure aspect preserved, bottom-aligned',
        () {
          final rects = MuscleOverlayLayout.figureRects(box, view);
          expect(rects, hasLength(view == OverlayView.both ? 2 : 1));
          for (final r in rects) {
            expect((Offset.zero & box).contains(r.topLeft), isTrue);
            expect(r.right, lessThanOrEqualTo(box.width + 1e-9));
            expect(r.bottom, lessThanOrEqualTo(box.height + 1e-9));
            expect(r.width / r.height, closeTo(aspect, 1e-9));
          }
          expect(rects.first.bottom, closeTo(box.height * 0.96, 1e-9));
        },
      );
    }

    test('none places no figures', () {
      expect(MuscleOverlayLayout.figureRects(box, OverlayView.none), isEmpty);
      expect(MuscleOverlayLayout.sides(OverlayView.none), isEmpty);
    });

    test('both figures sit side by side without overlapping', () {
      final rects = MuscleOverlayLayout.figureRects(box, OverlayView.both);
      expect(rects[0].right, lessThanOrEqualTo(rects[1].left));
    });

    test(
      'the same layout scales proportionally between preview and export',
      () {
        final preview = MuscleOverlayLayout.figureRects(
          const Size(360, 450),
          OverlayView.both,
        );
        final export = MuscleOverlayLayout.figureRects(
          RecapImageRenderer.panel.size,
          OverlayView.both,
        );
        final k = RecapImageRenderer.panel.width / 360;
        for (var i = 0; i < 2; i++) {
          expect(export[i].left, closeTo(preview[i].left * k, 1e-6));
          expect(export[i].top, closeTo(preview[i].top * k, 1e-6));
          expect(export[i].width, closeTo(preview[i].width * k, 1e-6));
        }
        expect(
          RecapImageRenderer.panel.width / RecapImageRenderer.panel.height,
          closeTo(MuscleOverlayLayout.photoAspect, 1e-9),
        );
      },
    );
  });

  group('RecapExportData', () {
    test('resolves title, date, stats and muscles for the image', () {
      final d = RecapExportData.from(
        entry: _entry(),
        summary: _summary,
        prCount: 0,
        weightUnit: WeightUnit.kg,
      );
      expect(d.title, 'Push Day');
      expect(d.dateLabel, 'Fri 25 Sep 2026');
      expect(d.stats.map((s) => s.label), [
        'Duration',
        'Sets',
        'Volume',
        'Exercises',
      ]);
      expect(d.stats.map((s) => s.value), ['00:45:00', '2', '1000 kg', '1']);
      expect(d.primary.toList(), [
        Muscle.chest,
        Muscle.triceps,
      ]); // head-to-toe order
      expect(d.primaryLabel, 'Chest  ·  Triceps');
      expect(d.secondaryLabel, 'Front Delts');
    });

    test('shows PRs instead of the exercise count when there were any', () {
      final d = RecapExportData.from(
        entry: _entry(),
        summary: _summary,
        prCount: 2,
        weightUnit: WeightUnit.lb,
      );
      expect(d.stats.last, (label: 'PRs', value: '2'));
      expect(d.stats[2].value, endsWith(' lb'));
    });

    test('falls back to "Workout" for an unnamed workout', () {
      final d = RecapExportData.from(
        entry: _entry(name: ''),
        summary: _summary,
        prCount: 0,
        weightUnit: WeightUnit.kg,
      );
      expect(d.title, 'Workout');
    });
  });

  group('rendering', () {
    final data = RecapExportData.from(
      entry: _entry(),
      summary: _summary,
      prCount: 1,
      weightUnit: WeightUnit.kg,
    );

    test('renders a 1080x1920 PNG without a photo', () async {
      final png = await RecapImageRenderer.renderPng(data);
      expect(png.sublist(1, 4), 'PNG'.codeUnits);
      expect(_pngSize(png), RecapImageRenderer.size);
    });

    test('renders with a photo of a different aspect ratio', () async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawRect(
        const Rect.fromLTWH(0, 0, 1200, 800),
        Paint()..color = const Color(0xFF884422),
      );
      final photo = await recorder.endRecording().toImage(1200, 800);
      final png = await RecapImageRenderer.renderPng(
        data,
        photo: photo,
        overlay: const OverlayConfig(opacity: 0.6),
      );
      expect(_pngSize(png), RecapImageRenderer.size);
      photo.dispose();
    });

    test(
      'the overlay has a transparent background and honours opacity',
      () async {
        Future<Uint8List> rgba(double opacity) async {
          const size = Size(200, 250);
          final recorder = ui.PictureRecorder();
          MuscleOverlayPainter(
            primary: {Muscle.chest},
            secondary: const {},
            opacity: opacity,
            view: OverlayView.front,
          ).paint(Canvas(recorder), size);
          final image = await recorder.endRecording().toImage(200, 250);
          final bytes = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          image.dispose();
          return bytes!.buffer.asUint8List();
        }

        int alphaAt(Uint8List px, Offset p) =>
            px[((p.dy.toInt() * 200) + p.dx.toInt()) * 4 + 3];

        // A point on the chest of the single front figure, via the shared layout.
        final rect = MuscleOverlayLayout.figureRects(
          const Size(200, 250),
          OverlayView.front,
        ).single;
        final k = rect.width / MuscleMapGeometry.designSize.width;
        final chest = rect.topLeft + kChestDesignPoint * k;

        final full = await rgba(1);
        final half = await rgba(0.5);
        expect(
          alphaAt(full, const Offset(2, 2)),
          0,
          reason: 'background stays transparent',
        );
        expect(alphaAt(full, chest), 255);
        expect(alphaAt(half, chest), inInclusiveRange(120, 135)); // ~50%
        expect(
          alphaAt(await rgba(0), chest),
          0,
          reason: 'opacity 0 draws nothing',
        );
      },
    );
  });
}
