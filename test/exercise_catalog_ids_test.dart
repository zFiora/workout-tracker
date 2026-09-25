// Built-in catalog id integrity, and the 108/110 split: Hip Abduction keeps
// 108 (its id since 2026-02); Incline triceps pushdown moved 108 → 110.

import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/home/exercises/exerciesesList.dart';
import 'package:workout_tracker/home/exercises/exercise_muscle_map.dart';
import 'package:workout_tracker/home/exercises/models/categoryModel.dart';
import 'package:workout_tracker/home/exercises/models/muscle.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';
import 'package:workout_tracker/home/session/services/muscle_summary_service.dart';
import 'package:workout_tracker/home/session/services/workoutSessionPRService.dart';
import 'package:workout_tracker/home/session/sessionViewModel.dart';

const hipAbduction = 108;
const inclineTricepsPushdown = 110;

final _t = DateTime(2026, 9, 25, 10);

WorkoutHistoryEntry workoutWith(Map<int, List<double>> weightsById) => WorkoutHistoryEntry(
      id: 'w',
      templateId: 't',
      templateName: 'T',
      templateIcon: '',
      startedAt: _t,
      endedAt: _t,
      duration: Duration.zero,
      logs: [
        for (final MapEntry(key: id, value: weights) in weightsById.entries)
          ExerciseLog(
            exerciseId: id,
            exerciseName: ExercisesViewModel.byId(id)!.name,
            exerciseIcon: '',
            sets: [
              for (final w in weights) PerformedSet(weight: w, reps: 10, timestamp: _t),
            ],
          ),
      ],
    );

void main() {
  group('catalog ids', () {
    test('no built-in exercise id is duplicated', () {
      final seen = <int, String>{};
      final duplicates = <String>[];
      for (final e in ExercisesViewModel.builtIn) {
        final previous = seen[e.id];
        if (previous != null) duplicates.add('${e.id}: "$previous" and "${e.name}"');
        seen[e.id] = e.name;
      }
      expect(duplicates, isEmpty);
    });

    test('built-in ids stay below the reserved custom-exercise range', () {
      for (final e in ExercisesViewModel.builtIn) {
        expect(e.id, lessThan(1000000), reason: e.name);
      }
    });
  });

  group('Hip Abduction (108) and Incline triceps pushdown (110)', () {
    test('have distinct ids with their own names, categories and images', () {
      final hip = ExercisesViewModel.byId(hipAbduction)!;
      final tri = ExercisesViewModel.byId(inclineTricepsPushdown)!;
      expect(hip.name, 'Hip Abduction');
      expect(hip.category, WorkoutCategory.legs);
      expect(hip.workoutImage, 'assets/workouts/legs/hip_abduction.png');
      expect(tri.name, 'Incline triceps pushdown');
      expect(tri.category, WorkoutCategory.triceps);
      expect(tri.workoutImage, 'assets/workouts/tri/overhead_tri_cable_atlantis.webp');
    });

    test('each name appears exactly once in the catalog', () {
      final names = ExercisesViewModel.builtIn.map((e) => e.name).toList();
      expect(names.where((n) => n == 'Hip Abduction'), hasLength(1));
      expect(names.where((n) => n == 'Incline triceps pushdown'), hasLength(1));
    });

    test('id-keyed map resolution (templates, repeat workout, view template) '
        'agrees with first-match lookup (byId, sessions, edit template)', () {
      // templatesPage/viewTemplatePage build {id: exercise}; with duplicates
      // the later entry silently won there while byId returned the earlier.
      final byIdMap = {for (final e in ExercisesViewModel.builtIn) e.id: e};
      expect(byIdMap.length, ExercisesViewModel.builtIn.length);
      for (final id in [hipAbduction, inclineTricepsPushdown]) {
        expect(byIdMap[id]!.name, ExercisesViewModel.byId(id)!.name);
      }
    });

    test('a session started from a template logs both exercises under their own names', () {
      final vm = WorkoutSessionViewModel(
        templateId: 't',
        templateName: 'Mixed',
        templateIcon: '',
        exerciseIds: const [hipAbduction, inclineTricepsPushdown],
        exerciseCatalog: ExercisesViewModel.builtIn,
      );
      expect(vm.logs.keys, [hipAbduction, inclineTricepsPushdown]);
      expect(vm.logs[hipAbduction]!.exerciseName, 'Hip Abduction');
      expect(vm.logs[inclineTricepsPushdown]!.exerciseName, 'Incline triceps pushdown');
      expect(
        vm.logs[inclineTricepsPushdown]!.exerciseIcon,
        'assets/workouts/tri/overhead_tri_cable_atlantis.webp',
      );
    });

    test('adding one mid-session is not blocked by the other', () {
      final vm = WorkoutSessionViewModel(
        templateId: 't',
        templateName: 'Legs',
        templateIcon: '',
        exerciseIds: const [hipAbduction],
        exerciseCatalog: ExercisesViewModel.builtIn,
      )..addExercise(ExercisesViewModel.byId(inclineTricepsPushdown)!);
      expect(vm.logs.keys, containsAll([hipAbduction, inclineTricepsPushdown]));
    });

    test('PR history is tracked per exercise, not shared', () {
      final pr = WorkoutSessionPrService();
      final history = [
        workoutWith({hipAbduction: [120], inclineTricepsPushdown: [30]}),
      ];
      expect(pr.bestWeightAllTime(exerciseId: hipAbduction, history: history), 120);
      expect(pr.bestWeightAllTime(exerciseId: inclineTricepsPushdown, history: history), 30);
      // 35 on the pushdown is a PR even though Hip Abduction's best is 120.
      expect(
        pr.bestWeightHitIfAny(
          exerciseId: inclineTricepsPushdown,
          performedAt: _t,
          weight: 35,
          reps: 8,
          history: history,
        ),
        isNotNull,
      );
    });

    test('muscle mappings: 108 stays Hip Abduction, 110 is triceps', () {
      expect(kBuiltInExerciseMuscles[hipAbduction]!.primary, {Muscle.glutes});
      expect(kBuiltInExerciseMuscles[hipAbduction]!.secondary, isEmpty);
      expect(kBuiltInExerciseMuscles[inclineTricepsPushdown]!.primary, {Muscle.triceps});
      expect(kBuiltInExerciseMuscles[inclineTricepsPushdown]!.secondary, isEmpty);
    });

    test('muscle summary counts them as two different exercises', () {
      final summary = computeMuscleSummary(
        workoutWith({hipAbduction: [60, 60], inclineTricepsPushdown: [25]}),
      );
      expect(summary.primary, {Muscle.glutes, Muscle.triceps});
      expect(summary.setsPerMuscle[Muscle.glutes], 2);
      expect(summary.setsPerMuscle[Muscle.triceps], 1);
      expect(summary.unrecognizedExercises, isEmpty);
    });
  });
}
