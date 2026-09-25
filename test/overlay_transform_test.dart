// Overlay editing model: transform maths, bounds, persistence, and that the
// export draws the user's exact composition without touching the photo.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:workout_tracker/common/units/weight_unit.dart';
import 'package:workout_tracker/common/widgets/muscle_map/muscle_map_geometry.dart';
import 'package:workout_tracker/common/widgets/muscle_map/muscle_overlay.dart';
import 'package:workout_tracker/home/exercises/models/muscle.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';
import 'package:workout_tracker/home/session/recap/progress_photo_store.dart';
import 'package:workout_tracker/home/session/recap/recap_export.dart';
import 'package:workout_tracker/home/session/recap/workout_recap.dart';
import 'package:workout_tracker/home/session/recap/workout_recap_store.dart';
import 'package:workout_tracker/home/session/services/muscle_summary_service.dart';

const frame = Size(400, 500);
const chestDesign = Offset(98, 118); // inside the left pec

final _t = DateTime(2026, 9, 25, 18);

const _summary = MuscleSummary(
  primary: {Muscle.chest},
  secondary: {},
  setsPerMuscle: {Muscle.chest: 3},
  unrecognizedExercises: [],
);

/// Where [designPoint] of the single front figure lands in a [box] once the
/// user's [t] is applied — the same maths the painter uses.
Offset placed(Offset designPoint, Size box, OverlayTransform t) {
  final rect = MuscleOverlayLayout.figureRects(box, OverlayView.front).single;
  final k = rect.width / MuscleMapGeometry.designSize.width;
  final p = rect.topLeft + designPoint * k;
  final pivot = MuscleOverlayLayout.anchor(box, OverlayView.front);
  final v = (p - pivot) * t.scale;
  final rotated = Offset(
    v.dx * math.cos(t.rotation) - v.dy * math.sin(t.rotation),
    v.dx * math.sin(t.rotation) + v.dy * math.cos(t.rotation),
  );
  return pivot +
      Offset(t.offset.dx * box.width, t.offset.dy * box.height) +
      rotated;
}

void main() {
  group('OverlayTransform', () {
    test('defaults to the identity (default placement)', () {
      expect(OverlayConfig.defaults.transform, OverlayTransform.identity);
      expect(OverlayConfig.defaults.view, OverlayView.both);
      expect(OverlayConfig.defaults.opacity, OverlayConfig.defaultOpacity);
      expect(OverlayTransform.identity.isIdentity, isTrue);
    });

    test('the anchor is the centre of the default figure placement', () {
      final rects = MuscleOverlayLayout.figureRects(frame, OverlayView.both);
      expect(
        MuscleOverlayLayout.anchor(frame, OverlayView.both),
        rects[0].expandToInclude(rects[1]).center,
      );
    });

    test(
      'drag moves by the pixel delta, stored as a fraction of the frame',
      () {
        final t = OverlayTransform.fromGesture(
          OverlayTransform.identity,
          frame: frame,
          view: OverlayView.front,
          translation: const Offset(40, -50),
        );
        expect(t.offset.dx, closeTo(0.1, 1e-9));
        expect(t.offset.dy, closeTo(-0.1, 1e-9));
        expect(t.scale, 1);
      },
    );

    test('drags accumulate from the gesture start', () {
      final first = OverlayTransform.fromGesture(
        OverlayTransform.identity,
        frame: frame,
        view: OverlayView.front,
        translation: const Offset(20, 0),
      );
      final second = OverlayTransform.fromGesture(
        first,
        frame: frame,
        view: OverlayView.front,
        translation: const Offset(20, 0),
      );
      expect(second.offset.dx, closeTo(0.1, 1e-9));
    });

    test('pinch scales relative to the gesture start and is clamped', () {
      final start = const OverlayTransform(scale: 1.5);
      double scaled(double f) => OverlayTransform.fromGesture(
        start,
        frame: frame,
        view: OverlayView.both,
        scaleFactor: f,
      ).scale;
      expect(scaled(1.2), closeTo(1.8, 1e-9));
      expect(scaled(10), OverlayTransform.maxScale);
      expect(scaled(0.01), OverlayTransform.minScale);
    });

    test('rotation adds up, snaps to upright near 0 and stays in (-π, π]', () {
      double rotated(double start, double delta) =>
          OverlayTransform.fromGesture(
            OverlayTransform(rotation: start),
            frame: frame,
            view: OverlayView.front,
            rotationDelta: delta,
          ).rotation;
      expect(rotated(0, 0.5), closeTo(0.5, 1e-9));
      expect(
        rotated(0.5, -0.47),
        0,
        reason: 'within the snap angle of upright',
      );
      expect(rotated(3, 1), closeTo(4 - 2 * math.pi, 1e-9));
    });

    test('the overlay centre can never leave the frame', () {
      for (final d in const [
        Offset(5000, 0),
        Offset(-5000, 0),
        Offset(0, 5000),
        Offset(0, -5000),
      ]) {
        final t = OverlayTransform.fromGesture(
          OverlayTransform.identity,
          frame: frame,
          view: OverlayView.front,
          translation: d,
        );
        final center =
            MuscleOverlayLayout.anchor(frame, OverlayView.front) +
            Offset(t.offset.dx * frame.width, t.offset.dy * frame.height);
        expect(
          center.dx,
          inInclusiveRange(
            frame.width * 0.05 - 1e-9,
            frame.width * 0.95 + 1e-9,
          ),
        );
        expect(
          center.dy,
          inInclusiveRange(
            frame.height * 0.05 - 1e-9,
            frame.height * 0.95 + 1e-9,
          ),
        );
      }
    });

    test('is resolution independent (same relative placement at any size)', () {
      const t = OverlayTransform(
        offset: Offset(0.12, -0.08),
        scale: 1.3,
        rotation: 0.2,
      );
      final small = placed(chestDesign, frame, t);
      final big = placed(chestDesign, frame * 2.46, t);
      expect(big.dx, closeTo(small.dx * 2.46, 1e-6));
      expect(big.dy, closeTo(small.dy * 2.46, 1e-6));
    });
  });

  group('OverlayConfig persistence', () {
    test('round-trips mode, position, scale, rotation and opacity', () {
      const config = OverlayConfig(
        view: OverlayView.back,
        transform: OverlayTransform(
          offset: Offset(0.2, -0.15),
          scale: 1.7,
          rotation: -0.3,
        ),
        opacity: 0.55,
      );
      final back = OverlayConfig.fromJson(
        jsonDecode(jsonEncode(config.toJson())) as Map<String, dynamic>,
      );
      expect(back, config);
    });

    test('"none" mode persists', () {
      const config = OverlayConfig(view: OverlayView.none);
      expect(OverlayConfig.fromJson(config.toJson()).view, OverlayView.none);
    });

    test('bad or missing values fall back safely', () {
      expect(OverlayConfig.fromJson(null), OverlayConfig.defaults);
      final c = OverlayConfig.fromJson({
        'view': 'sideways',
        'opacity': 7,
        'transform': {'dx': double.nan, 'scale': 99, 'rotation': 10},
      });
      expect(c.view, OverlayView.both);
      expect(c.opacity, 1);
      expect(c.transform.offset, Offset.zero);
      expect(c.transform.scale, OverlayTransform.maxScale);
      expect(c.transform.rotation, closeTo(10 - 4 * math.pi, 1e-9));
    });

    test(
      'recaps saved before the editor (v1, no overlay) load with the default overlay',
      () {
        final v1 = {
          'version': 1,
          'workoutId': 'w1',
          'summary': _summary.toJson(),
          'prCount': 0,
          'createdAt': _t.toIso8601String(),
          'photoFileName': 'p.jpg',
        };
        final r = WorkoutRecap.fromJson(v1);
        expect(r.overlay, OverlayConfig.defaults);
        expect(r.photoFileName, 'p.jpg');
      },
    );

    test('a v2 recap round-trips its overlay', () {
      const overlay = OverlayConfig(
        view: OverlayView.front,
        transform: OverlayTransform(offset: Offset(-0.1, 0.05), scale: 0.8),
        opacity: 0.4,
      );
      final r = WorkoutRecap(
        workoutId: 'w1',
        summary: _summary,
        prCount: 1,
        createdAt: _t,
        photoFileName: 'p.jpg',
        overlay: overlay,
      );
      expect(r.toJson()['version'], 2);
      final back = WorkoutRecap.fromJson(
        jsonDecode(jsonEncode(r.toJson())) as Map<String, dynamic>,
      );
      expect(back.overlay, overlay);
      // Changing the photo keeps the composition; changing it keeps the photo.
      expect(back.withPhoto('q.jpg').overlay, overlay);
      expect(back.withOverlay(OverlayConfig.defaults).photoFileName, 'p.jpg');
    });
  });

  group('store + export with a real photo file', () {
    late Directory tmp;
    late Box<String> box;
    late ProgressPhotoStore photos;
    late WorkoutRecapStore store;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('overlay_test');
      Hive.init('${tmp.path}/hive');
      box = await Hive.openBox<String>(WorkoutRecapStore.boxName);
      photos = ProgressPhotoStore(baseDir: () async => tmp);
      store = WorkoutRecapStore(box: box, photos: photos);
    });

    tearDown(() async {
      await Hive.deleteFromDisk();
      await Hive.close();
      if (await tmp.exists()) await tmp.delete(recursive: true);
    });

    Future<Uint8List> solidPng(Color color, int w, int h) async {
      final r = ui.PictureRecorder();
      Canvas(r).drawRect(
        Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        Paint()..color = color,
      );
      final img = await r.endRecording().toImage(w, h);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      return bytes!.buffer.asUint8List();
    }

    test(
      'saving an edited overlay persists it and restores it after reopening',
      () async {
        final src = File('${tmp.path}/src.png')
          ..writeAsBytesSync(await solidPng(const Color(0xFF884422), 40, 50));
        final name = await photos.persist(src.path);
        var recap = WorkoutRecap(
          workoutId: 'w1',
          summary: _summary,
          prCount: 0,
          createdAt: _t,
        );
        await store.put(recap);
        recap = await store.setPhoto(recap, name);

        const edited = OverlayConfig(
          view: OverlayView.front,
          transform: OverlayTransform(
            offset: Offset(0.15, -0.1),
            scale: 1.4,
            rotation: 0.25,
          ),
          opacity: 0.5,
        );
        await store.setOverlay(recap, edited);

        await box.close(); // "restart"
        box = await Hive.openBox<String>(WorkoutRecapStore.boxName);
        final reopened = WorkoutRecapStore(box: box, photos: photos).get('w1')!;
        expect(reopened.overlay, edited);
        expect(
          reopened.photoFileName,
          name,
          reason: 'overlay edits never replace the photo',
        );
      },
    );

    test(
      'the original photo file is never modified by editing or exporting',
      () async {
        final bytes = await solidPng(const Color(0xFF3366AA), 120, 150);
        final src = File('${tmp.path}/src.png')..writeAsBytesSync(bytes);
        final name = await photos.persist(src.path);
        final stored = (await photos.resolve(name))!;
        final before = stored.readAsBytesSync();
        final modifiedBefore = stored.lastModifiedSync();

        var recap = WorkoutRecap(
          workoutId: 'w1',
          summary: _summary,
          prCount: 0,
          createdAt: _t,
        );
        await store.put(recap);
        recap = await store.setPhoto(recap, name);
        recap = await store.setOverlay(
          recap,
          const OverlayConfig(opacity: 0.3),
        );

        final image = await decodePhotoForExport(stored);
        final data = RecapExportData.from(
          entry: WorkoutHistoryEntry(
            id: 'w1',
            templateId: 't',
            templateName: 'Chest',
            templateIcon: '',
            startedAt: _t,
            endedAt: _t,
            duration: Duration.zero,
            logs: const [],
          ),
          summary: _summary,
          prCount: 0,
          weightUnit: WeightUnit.kg,
        );
        await RecapImageRenderer.renderPng(
          data,
          photo: image,
          overlay: recap.overlay,
        );
        image.dispose();

        expect(stored.readAsBytesSync(), before);
        expect(stored.lastModifiedSync(), modifiedBefore);
      },
    );
  });

  group('export draws the exact composition', () {
    const photoColor = Color(
      0xFF20B040,
    ); // green: nothing in the overlay is green
    final data = RecapExportData.from(
      entry: WorkoutHistoryEntry(
        id: 'w1',
        templateId: 't',
        templateName: 'Chest',
        templateIcon: '',
        startedAt: _t,
        endedAt: _t,
        duration: Duration.zero,
        logs: const [],
      ),
      summary: _summary,
      prCount: 0,
      weightUnit: WeightUnit.kg,
    );

    Future<ui.Image> solidPhoto() async {
      final r = ui.PictureRecorder();
      Canvas(r).drawRect(
        const Rect.fromLTWH(0, 0, 800, 1000),
        Paint()..color = photoColor,
      );
      return r.endRecording().toImage(800, 1000);
    }

    Future<Uint8List> render(OverlayConfig overlay) async {
      final photo = await solidPhoto();
      final r = ui.PictureRecorder();
      RecapImageRenderer.paint(Canvas(r), data, photo: photo, overlay: overlay);
      final img = await r.endRecording().toImage(
        RecapImageRenderer.size.width.toInt(),
        RecapImageRenderer.size.height.toInt(),
      );
      final bytes = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      img.dispose();
      photo.dispose();
      return bytes!.buffer.asUint8List();
    }

    Color pixel(Uint8List px, Offset p) {
      final i =
          ((p.dy.round() * RecapImageRenderer.size.width.toInt()) +
              p.dx.round()) *
          4;
      return Color.fromARGB(px[i + 3], px[i], px[i + 1], px[i + 2]);
    }

    bool isPhoto(Color c) =>
        (c.r - photoColor.r).abs() < 0.08 &&
        (c.g - photoColor.g).abs() < 0.08 &&
        (c.b - photoColor.b).abs() < 0.08;

    Offset onExport(Offset designPoint, OverlayTransform t) =>
        RecapImageRenderer.panel.topLeft +
        placed(designPoint, RecapImageRenderer.panel.size, t);

    test(
      'the overlay sits at the user position/scale/rotation, photo elsewhere',
      () async {
        // Far enough right (and smaller) that the body no longer covers the
        // default chest spot.
        const moved = OverlayTransform(
          offset: Offset(0.3, -0.1),
          scale: 0.8,
          rotation: 0.3,
        );
        final px = await render(
          const OverlayConfig(
            view: OverlayView.front,
            transform: moved,
            opacity: 1,
          ),
        );

        // The chest is drawn where the user put it (volt blue, not photo green)…
        final chestNow = pixel(px, onExport(chestDesign, moved));
        expect(isPhoto(chestNow), isFalse);
        expect(chestNow.b, greaterThan(chestNow.g));
        // …and the default spot shows the untouched photo.
        expect(
          isPhoto(pixel(px, onExport(chestDesign, OverlayTransform.identity))),
          isTrue,
        );
      },
    );

    test(
      'opacity is applied (photo shows through the chest at low opacity)',
      () async {
        final opaque = pixel(
          await render(
            const OverlayConfig(view: OverlayView.front, opacity: 1),
          ),
          onExport(chestDesign, OverlayTransform.identity),
        );
        final faint = pixel(
          await render(
            const OverlayConfig(view: OverlayView.front, opacity: 0.3),
          ),
          onExport(chestDesign, OverlayTransform.identity),
        );
        // 30% overlay over 70% photo, channel by channel.
        expect(faint.r, closeTo(0.3 * opaque.r + 0.7 * photoColor.r, 0.02));
        expect(faint.g, closeTo(0.3 * opaque.g + 0.7 * photoColor.g, 0.02));
        expect(faint.b, closeTo(0.3 * opaque.b + 0.7 * photoColor.b, 0.02));
      },
    );

    test('"none" exports the photo without any overlay', () async {
      final px = await render(const OverlayConfig(view: OverlayView.none));
      expect(
        isPhoto(pixel(px, onExport(chestDesign, OverlayTransform.identity))),
        isTrue,
      );
    });
  });
}
