// Post-workout summary page, stats, and the reusable muscle map widgets.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/common/units/weight_unit.dart';
import 'package:workout_tracker/common/widgets/muscle_map/muscle_map_geometry.dart';
import 'package:workout_tracker/common/widgets/muscle_map/muscle_map_painter.dart';
import 'package:workout_tracker/common/widgets/muscle_map/muscle_map_view.dart';
import 'package:workout_tracker/common/widgets/muscle_map/muscle_overlay.dart';
import 'package:workout_tracker/home/exercises/models/muscle.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';
import 'package:workout_tracker/home/session/pages/progress_photo_editor_page.dart';
import 'package:workout_tracker/home/session/pages/workout_summary_page.dart';
import 'package:workout_tracker/home/session/recap/recap_export.dart';
import 'package:workout_tracker/home/session/recap/progress_photo_store.dart';
import 'package:workout_tracker/home/session/recap/workout_recap.dart';
import 'package:workout_tracker/home/session/recap/workout_recap_store.dart';
import 'package:workout_tracker/home/session/services/muscle_summary_service.dart';
import 'package:workout_tracker/home/session/services/workout_summary_stats.dart';

final _t = DateTime(2026, 9, 25, 10);

PerformedSet s({
  SetType type = SetType.work,
  double weight = 100,
  int reps = 5,
}) => PerformedSet(weight: weight, reps: reps, timestamp: _t, type: type);

WorkoutHistoryEntry workout({List<ExerciseLog>? logs}) => WorkoutHistoryEntry(
  id: 'w1',
  templateId: 't1',
  templateName: 'Push Day',
  templateIcon: '',
  startedAt: _t,
  endedAt: _t.add(const Duration(minutes: 45, seconds: 30)),
  duration: const Duration(minutes: 45, seconds: 30),
  logs:
      logs ??
      [
        // Bench (id 3): warm-up + 2 work sets.
        ExerciseLog(
          exerciseId: 3,
          exerciseName: 'Bench Press (Barbell)',
          exerciseIcon: '',
          sets: [
            s(type: SetType.warmup, weight: 40),
            s(),
            s(),
          ],
        ),
        // Pushdown (id 18): 1 drop set.
        ExerciseLog(
          exerciseId: 18,
          exerciseName: 'Triceps Push Down',
          exerciseIcon: '',
          sets: [s(type: SetType.dropset, weight: 20, reps: 10)],
        ),
        // Planned but skipped.
        ExerciseLog(exerciseId: 19, exerciseName: 'Curl', exerciseIcon: ''),
      ],
);

Future<void> pumpSummary(WidgetTester tester, WorkoutSummaryPage page) async {
  tester.view.physicalSize = const Size(1080, 3600);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (ctx) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(
                ctx,
              ).push(MaterialPageRoute(builder: (_) => page)),
              child: const Text('home'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('home'));
  await tester.pumpAndSettle();
}

/// Scrolls [finder] into view, then taps it (the recap page is taller than
/// the test viewport once a photo is shown).
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// In-memory recap store: no Hive, no disk.
class FakeRecapStore extends WorkoutRecapStore {
  final Map<String, WorkoutRecap> saved = {};
  @override
  WorkoutRecap? get(String workoutId) => saved[workoutId];
  @override
  Future<void> put(WorkoutRecap recap) async => saved[recap.workoutId] = recap;
  @override
  Future<WorkoutRecap> setPhoto(WorkoutRecap recap, String? fileName) async {
    final updated = recap.withPhoto(fileName);
    saved[recap.workoutId] = updated;
    return updated;
  }

  @override
  Future<WorkoutRecap> setOverlay(
    WorkoutRecap recap,
    OverlayConfig config,
  ) async {
    final updated = recap.withOverlay(config);
    saved[recap.workoutId] = updated;
    return updated;
  }
}

/// In-memory photo store: records copies/deletes; never touches the disk.
class FakePhotoStore extends ProgressPhotoStore {
  final Set<String> files = {};
  final List<String> persistedFrom = [];
  int _n = 0;
  @override
  Future<String> persist(String sourcePath) async {
    persistedFrom.add(sourcePath);
    final name = 'photo${_n++}.jpg';
    files.add(name);
    return name;
  }

  @override
  Future<File?> resolve(String fileName) async =>
      files.contains(fileName) ? File('/fake/progress_photos/$fileName') : null;
  @override
  Future<void> delete(String fileName) async => files.remove(fileName);
}

WorkoutRecap recapFor(
  WorkoutHistoryEntry e,
  MuscleSummary summary, {
  int prCount = 0,
  String? photo,
}) => WorkoutRecap(
  workoutId: e.id,
  summary: summary,
  prCount: prCount,
  createdAt: _t,
  photoFileName: photo,
);

const _calvesOnly = MuscleSummary(
  primary: {Muscle.calves},
  secondary: {Muscle.hamstrings},
  setsPerMuscle: {Muscle.calves: 4, Muscle.hamstrings: 4},
  unrecognizedExercises: [],
);

void main() {
  group('WorkoutSummaryStats', () {
    test(
      'counts exercises with sets, working sets, and History-equivalent volume',
      () {
        final stats = WorkoutSummaryStats.fromEntry(workout());
        expect(stats.duration, const Duration(minutes: 45, seconds: 30));
        expect(stats.exercisesWithSets, 2); // skipped curl excluded
        expect(stats.workingSets, 3); // 2 work + 1 drop, warm-up excluded
        // 40×5 + 100×5 + 100×5 + 20×10 — the same total History shows.
        expect(stats.volumeKg, 1400);
      },
    );

    test('duplicate exercise entries count as one exercise', () {
      final stats = WorkoutSummaryStats.fromEntry(
        workout(
          logs: [
            ExerciseLog(
              exerciseId: 3,
              exerciseName: 'Bench',
              exerciseIcon: '',
              sets: [s()],
            ),
            ExerciseLog(
              exerciseId: 3,
              exerciseName: 'Bench',
              exerciseIcon: '',
              sets: [s()],
            ),
          ],
        ),
      );
      expect(stats.exercisesWithSets, 1);
      expect(stats.workingSets, 2);
    });
  });

  group('WorkoutSummaryPage', () {
    testWidgets('shows name, stats, body map, legend and muscle list', (
      tester,
    ) async {
      await pumpSummary(
        tester,
        WorkoutSummaryPage(entry: workout(), prCount: 2),
      );

      expect(find.text('Workout Complete'), findsOneWidget);
      expect(find.text('Push Day'), findsOneWidget);
      expect(find.text('00:45:30'), findsOneWidget);
      expect(find.text('Exercises'), findsOneWidget);
      expect(find.text('2'), findsWidgets); // exercises and PRs
      expect(find.text('Working sets'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('1400 kg'), findsOneWidget);
      expect(find.text('PRs'), findsOneWidget);

      expect(
        find.text('MUSCLE GROUPS WORKED'),
        findsOneWidget,
      ); // SectionHeader uppercases
      expect(find.byType(MuscleMapView), findsOneWidget);
      expect(find.text('Front'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);

      // Bench → chest | front delts, triceps; pushdown → triceps primary.
      expect(find.text('Chest'), findsOneWidget);
      expect(find.text('Triceps'), findsOneWidget);
      expect(find.text('Front Delts'), findsOneWidget);
      // Legend + grouped chips (with working-set counts per muscle).
      expect(find.text('Primary'), findsOneWidget);
      expect(find.text('Secondary'), findsOneWidget);
      expect(find.text('PRIMARY'), findsOneWidget);
      expect(find.text('SECONDARY'), findsOneWidget);
      expect(
        find.text('3 sets'),
        findsOneWidget,
      ); // triceps: 2 bench + 1 pushdown
      expect(find.text('2 sets'), findsNWidgets(2)); // chest, front delts
      expect(find.text('WORKOUT COMPLETE'), findsOneWidget);
      expect(find.text('Muscle summary unavailable'), findsNothing);
    });

    testWidgets('volume follows the weight unit', (tester) async {
      await pumpSummary(
        tester,
        WorkoutSummaryPage(entry: workout(), weightUnit: WeightUnit.lb),
      );
      expect(find.text('${WeightUnit.lb.format(1400)} lb'), findsOneWidget);
    });

    testWidgets('PR stat is hidden when there were no PRs', (tester) async {
      await pumpSummary(tester, WorkoutSummaryPage(entry: workout()));
      expect(find.text('PRs'), findsNothing);
    });

    testWidgets('shows the unavailable state when nothing is recognized', (
      tester,
    ) async {
      await pumpSummary(
        tester,
        WorkoutSummaryPage(
          entry: workout(),
          computeSummary: (e) => computeMuscleSummary(e, resolver: (_) => null),
        ),
      );
      expect(find.text('Muscle summary unavailable'), findsOneWidget);
      expect(find.byType(MuscleMapView), findsNothing);
      // Stats still render.
      expect(find.text('Working sets'), findsOneWidget);
    });

    testWidgets(
      'a failing calculation shows the unavailable state, not an error',
      (tester) async {
        // The page deliberately logs the swallowed failure. Capture it so the
        // test asserts that behaviour instead of printing an error-looking line
        // into the test output.
        // (Restored inside the body: the framework verifies debugPrint is back
        // to normal before tear-downs run.)
        final logged = <String>[];
        final originalDebugPrint = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) =>
            logged.add(message ?? '');

        var calls = 0;
        try {
          await pumpSummary(
            tester,
            WorkoutSummaryPage(
              entry: workout(),
              computeSummary: (_) {
                calls++;
                throw StateError('boom');
              },
            ),
          );
        } finally {
          debugPrint = originalDebugPrint;
        }

        expect(
          tester.takeException(),
          isNull,
          reason: 'the failure must not escape',
        );
        expect(find.text('Muscle summary unavailable'), findsOneWidget);
        expect(find.byType(MuscleMapView), findsNothing);
        // The rest of the summary still renders.
        expect(find.text('Push Day'), findsOneWidget);
        expect(find.text('Working sets'), findsOneWidget);
        expect(find.text('Done'), findsOneWidget);
        // Computed once (not retried on every rebuild) and logged once with the cause.
        expect(calls, 1);
        expect(logged, [contains('muscle summary failed: Bad state: boom')]);
      },
    );

    testWidgets('an empty workout shows the unavailable state', (tester) async {
      await pumpSummary(
        tester,
        WorkoutSummaryPage(entry: workout(logs: const [])),
      );
      expect(find.text('Muscle summary unavailable'), findsOneWidget);
    });

    testWidgets('shows the persisted summary, not a recalculation', (
      tester,
    ) async {
      final entry = workout(); // bench + pushdown would compute chest/triceps
      await pumpSummary(
        tester,
        WorkoutSummaryPage(
          entry: entry,
          recap: recapFor(entry, _calvesOnly, prCount: 4),
          computeSummary: (_) => fail('must not recompute when a recap exists'),
          recapStore: FakeRecapStore(),
          photoStore: FakePhotoStore(),
        ),
      );
      expect(find.text('Calves'), findsOneWidget);
      expect(find.text('Hamstrings'), findsOneWidget);
      expect(find.text('Chest'), findsNothing);
      expect(find.text('Triceps'), findsNothing);
      // PR count also comes from the recap.
      expect(find.text('PRs'), findsOneWidget);
      expect(find.text('4'), findsWidgets);
    });

    testWidgets('history mode is labelled as a past summary', (tester) async {
      final entry = workout();
      await pumpSummary(
        tester,
        WorkoutSummaryPage(
          entry: entry,
          recap: recapFor(entry, _calvesOnly),
          mode: WorkoutSummaryMode.history,
          recapStore: FakeRecapStore(),
          photoStore: FakePhotoStore(),
        ),
      );
      expect(find.text('Workout Summary'), findsOneWidget);
      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.text('WORKOUT COMPLETE'), findsNothing);
    });

    group('progress photo', () {
      late FakeRecapStore recaps;
      late FakePhotoStore photos;
      late List<ImageSource> picks;
      late WorkoutHistoryEntry entry;

      setUp(() {
        recaps = FakeRecapStore();
        photos = FakePhotoStore();
        picks = [];
        entry = workout();
      });

      WorkoutSummaryPage page({
        String? photo,
        String? pickResult = '/tmp/picked.jpg',
        OverlayConfig overlay = OverlayConfig.defaults,
        ShareImage? share,
      }) {
        final recap = recapFor(
          entry,
          _calvesOnly,
          photo: photo,
        ).withOverlay(overlay);
        recaps.saved[entry.id] = recap;
        if (photo != null) photos.files.add(photo);
        return WorkoutSummaryPage(
          entry: entry,
          recap: recap,
          recapStore: recaps,
          photoStore: photos,
          pickPhoto: (source) async {
            picks.add(source);
            return pickResult;
          },
          shareImage: share ?? shareRecapImage,
        );
      }

      OverlayConfig previewOverlay(WidgetTester tester) => tester
          .widget<ProgressPhotoPreview>(find.byType(ProgressPhotoPreview))
          .overlay;

      testWidgets('starts empty with camera and gallery options', (
        tester,
      ) async {
        await pumpSummary(tester, page());
        expect(find.text('PROGRESS PHOTO'), findsOneWidget);
        expect(find.text('Add Progress Photo'), findsOneWidget);
        expect(find.text('Camera'), findsOneWidget);
        expect(find.text('Gallery'), findsOneWidget);
        expect(find.byType(ProgressPhotoPreview), findsNothing);
      });

      testWidgets(
        'camera: photo is stored locally, then opens the editor; Save persists the overlay',
        (tester) async {
          await pumpSummary(tester, page());
          await tester.tap(find.text('Camera'));
          await tester.pumpAndSettle();

          expect(picks, [ImageSource.camera]);
          expect(photos.persistedFrom, ['/tmp/picked.jpg']);
          expect(recaps.saved[entry.id]!.photoFileName, 'photo0.jpg');

          // The editor opened straight away, at the default placement.
          expect(find.byType(ProgressPhotoEditorPage), findsOneWidget);
          await tester.tap(find.byKey(const ValueKey('overlay-mode-front')));
          await tester.drag(
            find.byKey(const ValueKey('overlay-editor-frame')),
            const Offset(60, 0),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('overlay-editor-save')));
          await tester.pumpAndSettle();

          final saved = recaps.saved[entry.id]!.overlay;
          expect(saved.view, OverlayView.front);
          expect(saved.transform.offset.dx, greaterThan(0));
          expect(recaps.saved[entry.id]!.photoFileName, 'photo0.jpg');

          // Back on the summary, the preview shows the saved composition.
          expect(find.byType(ProgressPhotoEditorPage), findsNothing);
          expect(previewOverlay(tester), saved);
          expect(find.text('Add Progress Photo'), findsNothing);
        },
      );

      testWidgets(
        'closing the editor after picking keeps the photo, default overlay',
        (tester) async {
          await pumpSummary(tester, page());
          await tester.tap(find.text('Gallery'));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('overlay-editor-close')));
          await tester.pumpAndSettle();
          expect(recaps.saved[entry.id]!.photoFileName, 'photo0.jpg');
          expect(recaps.saved[entry.id]!.overlay, OverlayConfig.defaults);
          expect(find.byType(ProgressPhotoPreview), findsOneWidget);
        },
      );

      testWidgets('cancelling the picker changes nothing', (tester) async {
        await pumpSummary(tester, page(pickResult: null));
        await tester.tap(find.text('Gallery'));
        await tester.pumpAndSettle();
        expect(picks, [ImageSource.gallery]);
        expect(photos.persistedFrom, isEmpty);
        expect(recaps.saved[entry.id]!.hasPhoto, isFalse);
        expect(find.text('Add Progress Photo'), findsOneWidget);
      });

      testWidgets('a saved photo is shown when the summary is reopened', (
        tester,
      ) async {
        await pumpSummary(tester, page(photo: 'saved.jpg'));
        expect(find.byType(ProgressPhotoPreview), findsOneWidget);
        expect(
          tester
              .widget<ProgressPhotoPreview>(find.byType(ProgressPhotoPreview))
              .photo
              .path,
          endsWith('saved.jpg'),
        );
      });

      testWidgets(
        'a saved composition is restored in the preview and the editor',
        (tester) async {
          const saved = OverlayConfig(
            view: OverlayView.back,
            transform: OverlayTransform(
              offset: Offset(0.12, -0.08),
              scale: 1.4,
              rotation: 0.2,
            ),
            opacity: 0.5,
          );
          await pumpSummary(tester, page(photo: 'saved.jpg', overlay: saved));
          expect(previewOverlay(tester), saved);

          await tapVisible(tester, find.text('Edit overlay'));
          expect(find.byType(ProgressPhotoEditorPage), findsOneWidget);
          expect(
            tester
                .widget<MuscleOverlay>(find.byType(MuscleOverlay).last)
                .config,
            saved,
          );
        },
      );

      testWidgets('tapping the photo opens the editor too', (tester) async {
        await pumpSummary(tester, page(photo: 'saved.jpg'));
        await tapVisible(
          tester,
          find.byKey(const ValueKey('progress-photo-preview')),
        );
        expect(find.byType(ProgressPhotoEditorPage), findsOneWidget);
      });

      testWidgets('closing the editor leaves the saved composition untouched', (
        tester,
      ) async {
        const saved = OverlayConfig(opacity: 0.4);
        await pumpSummary(tester, page(photo: 'saved.jpg', overlay: saved));
        await tapVisible(tester, find.text('Edit overlay'));
        await tester.tap(find.text('None'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('overlay-editor-close')));
        await tester.pumpAndSettle();
        expect(recaps.saved[entry.id]!.overlay, saved);
        expect(previewOverlay(tester), saved);
      });

      testWidgets('"None" hides the overlay in the preview once saved', (
        tester,
      ) async {
        await pumpSummary(tester, page(photo: 'saved.jpg'));
        await tapVisible(tester, find.text('Edit overlay'));
        await tester.tap(find.text('None'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('overlay-editor-save')));
        await tester.pumpAndSettle();
        expect(recaps.saved[entry.id]!.overlay.view, OverlayView.none);
        expect(
          find.descendant(
            of: find.byType(ProgressPhotoPreview),
            matching: find.byType(MuscleOverlay),
          ),
          findsNothing,
        );
      });

      testWidgets('sharing from the editor does not save the edit', (
        tester,
      ) async {
        var shares = 0;
        await pumpSummary(
          tester,
          page(
            photo: 'saved.jpg',
            share: (png, {required fileName, required subject, origin}) async =>
                shares++,
          ),
        );
        await tapVisible(tester, find.text('Edit overlay'));
        await tester.tap(find.text('Front'));
        await tester.pumpAndSettle();
        // The fake photo can't be decoded, so the export reports an error —
        // what matters here is that nothing was persisted.
        // Export reads the photo with real file I/O, so run it on real async.
        // The fake path can't be decoded; the page logs that and shows a
        // message — captured here so it's asserted, not printed.
        final logged = <String>[];
        final originalDebugPrint = debugPrint;
        debugPrint = (String? m, {int? wrapWidth}) => logged.add(m ?? '');
        try {
          await tester.runAsync(() async {
            await tester.tap(
              find.byKey(const ValueKey('overlay-editor-share')),
            );
            await Future<void>.delayed(const Duration(milliseconds: 200));
          });
          await tester.pumpAndSettle();
        } finally {
          debugPrint = originalDebugPrint;
        }
        expect(logged, [contains('export failed')]);
        expect(find.text("Couldn't create the image."), findsOneWidget);
        expect(recaps.saved[entry.id]!.overlay, OverlayConfig.defaults);
        expect(find.byType(ProgressPhotoEditorPage), findsOneWidget);
      });

      testWidgets(
        'remove detaches the photo from the recap (file deletion: see store tests)',
        (tester) async {
          await pumpSummary(tester, page(photo: 'saved.jpg'));
          await tapVisible(tester, find.text('Remove'));
          expect(recaps.saved[entry.id]!.hasPhoto, isFalse);
          expect(find.byType(ProgressPhotoPreview), findsNothing);
          expect(find.text('Add Progress Photo'), findsOneWidget);
        },
      );

      testWidgets(
        'change photo goes through the picker sheet, then the editor',
        (tester) async {
          await pumpSummary(tester, page(photo: 'saved.jpg'));
          await tapVisible(tester, find.text('Change photo'));
          await tester.tap(find.text('Choose from gallery'));
          await tester.pumpAndSettle();
          expect(picks, [ImageSource.gallery]);
          expect(recaps.saved[entry.id]!.photoFileName, 'photo0.jpg');
          expect(find.byType(ProgressPhotoEditorPage), findsOneWidget);
          await tester.tap(find.byKey(const ValueKey('overlay-editor-close')));
          await tester.pumpAndSettle();
        },
      );

      testWidgets(
        'no photo section without a saved recap (nothing to attach it to)',
        (tester) async {
          await pumpSummary(tester, WorkoutSummaryPage(entry: entry));
          expect(find.text('PROGRESS PHOTO'), findsNothing);
        },
      );
    });

    testWidgets(
      'Share renders an image locally and hands it to the share sheet',
      (tester) async {
        final shared = <({Uint8List png, String fileName, String subject})>[];
        final entry = workout();
        await pumpSummary(
          tester,
          WorkoutSummaryPage(
            entry: entry,
            recap: recapFor(entry, _calvesOnly),
            recapStore: FakeRecapStore(),
            photoStore: FakePhotoStore(),
            shareImage:
                (png, {required fileName, required subject, origin}) async {
                  shared.add((png: png, fileName: fileName, subject: subject));
                },
          ),
        );

        // Rendering uses the real engine, so let it run on real async.
        await tester.runAsync(() async {
          await tester.tap(find.byKey(const ValueKey('recap-share')));
          for (var i = 0; i < 50 && shared.isEmpty; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 20));
          }
        });
        await tester.pumpAndSettle();

        expect(shared, hasLength(1));
        expect(shared.single.png.sublist(1, 4), 'PNG'.codeUnits);
        expect(shared.single.fileName, 'zlift-20260925-1000.png');
        expect(shared.single.subject, startsWith('Push Day'));
      },
    );

    testWidgets('Share is not offered when there is nothing to show', (
      tester,
    ) async {
      await pumpSummary(
        tester,
        WorkoutSummaryPage(
          entry: workout(logs: const []),
          shareImage:
              (png, {required fileName, required subject, origin}) async =>
                  fail('should not share'),
        ),
      );
      expect(find.byKey(const ValueKey('recap-share')), findsNothing);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('Done returns to the previous screen', (tester) async {
      await pumpSummary(tester, WorkoutSummaryPage(entry: workout()));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.byType(WorkoutSummaryPage), findsNothing);
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('system back returns to the previous screen', (tester) async {
      await pumpSummary(tester, WorkoutSummaryPage(entry: workout()));
      final handled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(handled, isTrue);
      expect(find.byType(WorkoutSummaryPage), findsNothing);
      expect(find.text('home'), findsOneWidget);
    });
  });

  group('muscle map', () {
    test('every muscle is drawn on the front or back view', () {
      final drawn = {
        ...MuscleMapGeometry.muscles(BodySide.front).keys,
        ...MuscleMapGeometry.muscles(BodySide.back).keys,
      };
      expect(drawn, Muscle.values.toSet());
    });

    test('highlight precedence: primary > secondary > none', () {
      expect(
        muscleHighlight(
          Muscle.chest,
          primary: {Muscle.chest},
          secondary: {Muscle.chest},
        ),
        MuscleHighlight.primary,
      );
      expect(
        muscleHighlight(Muscle.biceps, primary: {}, secondary: {Muscle.biceps}),
        MuscleHighlight.secondary,
      );
      expect(
        muscleHighlight(Muscle.calves, primary: {}, secondary: {}),
        MuscleHighlight.none,
      );
    });

    testWidgets(
      'renders both sides and describes highlights for accessibility',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MuscleMapView(
                primary: {Muscle.chest},
                secondary: {Muscle.triceps},
              ),
            ),
          ),
        );
        expect(
          find.descendant(
            of: find.byType(MuscleMapView),
            matching: find.byType(CustomPaint),
          ),
          findsNWidgets(2),
        );
        expect(
          find.bySemanticsLabel(RegExp('Primary: Chest.*Secondary: Triceps')),
          findsOneWidget,
        );
        semantics.dispose();
      },
    );
  });
}
