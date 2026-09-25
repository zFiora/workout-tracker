// History ↔ saved recap: old workouts (no recap) open exactly as before;
// workouts with a recap offer their saved summary, fully offline.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_tracker/common/AppManager.dart';
import 'package:workout_tracker/home/session/recap/progress_photo_store.dart';
import 'package:workout_tracker/home/session/pages/progress_photo_editor_page.dart';
import 'package:workout_tracker/common/widgets/muscle_map/muscle_overlay.dart';
import 'package:workout_tracker/common/models/sex.dart';
import 'package:workout_tracker/home/exercises/models/muscle.dart';
import 'package:workout_tracker/home/history/pages/historySessionDetailedPage.dart';
import 'package:workout_tracker/home/history/repos/PREventRepository.dart';
import 'package:workout_tracker/home/history/repos/historyRepository.dart';
import 'package:workout_tracker/home/history/services/historyService.dart';
import 'package:workout_tracker/home/history/widgets/history_recap_card.dart';
import 'package:workout_tracker/home/measure/models/macro_profile.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';
import 'package:workout_tracker/home/session/pages/workout_summary_page.dart';
import 'package:workout_tracker/home/session/recap/workout_recap.dart';
import 'package:workout_tracker/home/session/recap/workout_recap_store.dart';
import 'package:workout_tracker/home/session/services/muscle_summary_service.dart';

class _Repo implements HistoryRepository {
  @override
  StreamSubscription<BoxEvent> watch(void Function(BoxEvent) onEvent) =>
      const Stream<BoxEvent>.empty().listen(onEvent);
  @override
  List<HistoryRecord> getAllRecords() => const [];
  @override
  WorkoutHistoryEntry? get(dynamic key) => null;
  @override
  Future<dynamic> add(WorkoutHistoryEntry entry) async => 0;
  @override
  Future<void> deleteByKey(dynamic key) async {}
  @override
  Future<void> clear() async {}
}

class _PrRepo implements PrEventsRepository {
  @override
  Future<void> putEventsForHistoryKey(
    dynamic k,
    List<Map<String, dynamic>> e,
  ) async {}
  @override
  Future<List<Map<String, dynamic>>> loadEventsForHistoryKey(dynamic k) async =>
      const [];
  @override
  Future<void> deleteEventsForHistoryKey(dynamic k) async {}
  @override
  Future<void> clearAll() async {}
}

class _Photos extends ProgressPhotoStore {
  @override
  Future<File?> resolve(String fileName) async => File('/fake/$fileName');
}

class _Recaps extends WorkoutRecapStore {
  final Map<String, WorkoutRecap> saved = {};
  @override
  WorkoutRecap? get(String workoutId) => saved[workoutId];
}

final _t = DateTime(2026, 9, 20, 9);

WorkoutHistoryEntry _entry(String id) => WorkoutHistoryEntry(
  id: id,
  templateId: 't',
  templateName: 'Leg Day',
  templateIcon: 'assets/workout_category/legs_emoji.png',
  startedAt: _t,
  endedAt: _t.add(const Duration(hours: 1)),
  duration: const Duration(hours: 1),
  logs: [
    ExerciseLog(
      exerciseId: 37, // Squat
      exerciseName: 'Squat',
      exerciseIcon: 'assets/workouts/legs/squat.png',
      sets: [PerformedSet(weight: 100, reps: 5, timestamp: _t)],
    ),
  ],
);

void main() {
  late Directory tmp;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    tmp = await Directory.systemTemp.createTemp('history_recap_test');
    Hive.init(tmp.path);
    if (!Hive.isAdapterRegistered(33)) Hive.registerAdapter(SexAdapter());
    if (!Hive.isAdapterRegistered(32)) {
      Hive.registerAdapter(MacroProfileAdapter());
    }
    await Hive.openBox<MacroProfile>('macrosProfileBox'); // read by AppManager
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await tmp.delete(recursive: true);
  });

  Future<void> pumpDetail(
    WidgetTester tester,
    WorkoutHistoryEntry entry,
    _Recaps recaps,
  ) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppManager(),
        child: MaterialApp(
          home: HistorySessionDetailPage(
            entry: entry,
            historyKey: 0,
            historyService: HistoryService(
              historyRepo: _Repo(),
              prRepo: _PrRepo(),
            ),
            recapStore: recaps,
            photoStore: _Photos(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'an old workout without a recap opens normally, with no summary card',
    (tester) async {
      await pumpDetail(tester, _entry('old'), _Recaps());
      expect(find.text('Leg Day'), findsWidgets);
      expect(find.text('Squat'), findsOneWidget); // exercises still listed
      expect(find.byType(HistoryRecapCard), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a workout with a recap offers its saved summary (offline, as saved)',
    (tester) async {
      final entry = _entry('new');
      // Frozen summary that differs from what Squat would compute today.
      final recaps = _Recaps()
        ..saved['new'] = WorkoutRecap(
          workoutId: 'new',
          summary: const MuscleSummary(
            primary: {Muscle.calves},
            secondary: {},
            setsPerMuscle: {Muscle.calves: 1},
            unrecognizedExercises: [],
          ),
          prCount: 0,
          createdAt: _t,
          photoFileName: 'p.jpg',
        );

      await pumpDetail(tester, entry, recaps);
      expect(find.byType(HistoryRecapCard), findsOneWidget);
      expect(find.text('Muscle summary'), findsOneWidget);
      expect(find.textContaining('Progress photo'), findsOneWidget);

      await tester.tap(find.byType(HistoryRecapCard));
      await tester.pumpAndSettle();

      expect(find.byType(WorkoutSummaryPage), findsOneWidget);
      expect(find.text('Workout Summary'), findsOneWidget);
      expect(find.text('Calves'), findsOneWidget);
      expect(find.text('Quads'), findsNothing); // not recalculated from Squat
    },
  );

  testWidgets('reopening from History restores the edited photo composition', (
    tester,
  ) async {
    const saved = OverlayConfig(
      view: OverlayView.front,
      transform: OverlayTransform(
        offset: Offset(0.18, -0.06),
        scale: 1.25,
        rotation: -0.15,
      ),
      opacity: 0.6,
    );
    final recaps = _Recaps()
      ..saved['edited'] = WorkoutRecap(
        workoutId: 'edited',
        summary: const MuscleSummary(
          primary: {Muscle.quads},
          secondary: {},
          setsPerMuscle: {Muscle.quads: 1},
          unrecognizedExercises: [],
        ),
        prCount: 0,
        createdAt: _t,
        photoFileName: 'p.jpg',
        overlay: saved,
      );

    await pumpDetail(tester, _entry('edited'), recaps);
    await tester.tap(find.byType(HistoryRecapCard));
    await tester.pumpAndSettle();

    final preview = find.byType(ProgressPhotoPreview);
    await tester.ensureVisible(preview);
    await tester.pumpAndSettle();
    expect(tester.widget<ProgressPhotoPreview>(preview).overlay, saved);
    expect(
      tester.widget<ProgressPhotoPreview>(preview).photo.path,
      endsWith('p.jpg'),
    );

    await tester.tap(find.text('Edit overlay'));
    await tester.pumpAndSettle();
    expect(find.byType(ProgressPhotoEditorPage), findsOneWidget);
    expect(
      tester.widget<MuscleOverlay>(find.byType(MuscleOverlay).last).config,
      saved,
    );
  });
}
