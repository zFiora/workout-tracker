// Muscle mapping + post-workout muscle summary calculation. Pure Dart:
// custom exercises are exercised through muscleTargetsForCustom and an
// injected resolver, so no Hive box is needed.

import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/home/exercises/exerciesesList.dart';
import 'package:workout_tracker/home/exercises/exercise_muscle_map.dart';
import 'package:workout_tracker/home/exercises/models/categoryModel.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/exercises/models/muscle.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';
import 'package:workout_tracker/home/session/services/muscle_summary_service.dart';

final _t = DateTime(2026, 9, 25, 10);

PerformedSet s({SetType type = SetType.work, double weight = 50, int reps = 10}) =>
    PerformedSet(weight: weight, reps: reps, timestamp: _t, type: type);

ExerciseLog log(int id, List<PerformedSet> sets, {String? name}) => ExerciseLog(
      exerciseId: id,
      exerciseName: name ?? 'Exercise $id',
      exerciseIcon: '',
      sets: sets,
    );

WorkoutHistoryEntry workout(List<ExerciseLog> logs) => WorkoutHistoryEntry(
      id: 'w1',
      templateId: 't1',
      templateName: 'Push Day',
      templateIcon: '',
      startedAt: _t,
      endedAt: _t.add(const Duration(minutes: 50)),
      duration: const Duration(minutes: 50),
      logs: logs,
    );

// Built-in ids used below (see exercise_muscle_map.dart):
const benchPress = 3; // chest | frontDelts, triceps
const tricepPushdown = 18; // triceps | —
const latPulldown = 7; // lats | biceps, traps, rearDelts
const barbellCurl = 19; // biceps | forearms
const squat = 37; // quads, glutes | hamstrings, lowerBack
const legExtension = 40; // quads | —

void main() {
  group('built-in mapping table', () {
    test('every built-in exercise id has a mapping', () {
      final missing = [
        for (final e in ExercisesViewModel.builtIn)
          if (!kBuiltInExerciseMuscles.containsKey(e.id)) '${e.id} ${e.name}',
      ];
      expect(missing, isEmpty);
    });

    test('there are no mappings for ids that are not in the catalog', () {
      final catalogIds = ExercisesViewModel.builtIn.map((e) => e.id).toSet();
      expect(kBuiltInExerciseMuscles.keys.toSet().difference(catalogIds), isEmpty);
    });

    test('every mapping has a primary muscle and no muscle is both primary and secondary', () {
      kBuiltInExerciseMuscles.forEach((id, t) {
        expect(t.primary, isNotEmpty, reason: 'id $id has no primary muscle');
        expect(t.primary.intersection(t.secondary), isEmpty, reason: 'id $id overlaps');
      });
    });
  });

  group('computeMuscleSummary', () {
    test('single exercise: primary and secondary from the table', () {
      final r = computeMuscleSummary(workout([log(benchPress, [s(), s(), s()])]));
      expect(r.primary, {Muscle.chest});
      expect(r.secondary, {Muscle.frontDelts, Muscle.triceps});
      expect(r.setsPerMuscle, {Muscle.chest: 3, Muscle.frontDelts: 3, Muscle.triceps: 3});
      expect(r.unrecognizedExercises, isEmpty);
      expect(r.hasMuscles, isTrue);
    });

    test('multiple exercises: unions of primary and secondary', () {
      final r = computeMuscleSummary(workout([
        log(latPulldown, [s()]),
        log(squat, [s()]),
      ]));
      expect(r.primary, {Muscle.lats, Muscle.quads, Muscle.glutes});
      expect(r.secondary, {
        Muscle.biceps, Muscle.traps, Muscle.rearDelts,
        Muscle.hamstrings, Muscle.lowerBack,
      });
    });

    test('multiple exercises contributing to the same muscle add their sets', () {
      final r = computeMuscleSummary(workout([
        log(squat, [s(), s()]),
        log(legExtension, [s(), s(), s()]),
      ]));
      expect(r.primary, containsAll({Muscle.quads, Muscle.glutes}));
      expect(r.setsPerMuscle[Muscle.quads], 5);
      expect(r.setsPerMuscle[Muscle.glutes], 2);
    });

    test('primary overrides secondary across exercises', () {
      // Bench: triceps secondary. Pushdown: triceps primary.
      final r = computeMuscleSummary(workout([
        log(benchPress, [s()]),
        log(tricepPushdown, [s()]),
      ]));
      expect(r.primary, {Muscle.chest, Muscle.triceps});
      expect(r.secondary, {Muscle.frontDelts});
      expect(r.primary.intersection(r.secondary), isEmpty);
      expect(r.setsPerMuscle[Muscle.triceps], 2); // counted from both
    });

    test('duplicate entries for the same exercise are merged', () {
      final r = computeMuscleSummary(workout([
        log(barbellCurl, [s(), s()]),
        log(barbellCurl, [s()]),
      ]));
      expect(r.primary, {Muscle.biceps});
      expect(r.secondary, {Muscle.forearms});
      expect(r.setsPerMuscle[Muscle.biceps], 3);
    });

    test('warm-up sets are excluded; work and drop sets count', () {
      final r = computeMuscleSummary(workout([
        log(benchPress, [s(type: SetType.warmup), s(), s(type: SetType.dropset)]),
      ]));
      expect(r.setsPerMuscle[Muscle.chest], 2);
    });

    test('an exercise with only warm-ups does not contribute', () {
      final r = computeMuscleSummary(workout([
        log(benchPress, [s(type: SetType.warmup)]),
        log(barbellCurl, [s()]),
      ]));
      expect(r.primary, {Muscle.biceps});
      expect(r.secondary, {Muscle.forearms});
    });

    test('zero-set (planned but skipped) exercises do not contribute', () {
      final r = computeMuscleSummary(workout([
        log(benchPress, []),
        log(barbellCurl, [s()]),
      ]));
      expect(r.primary, {Muscle.biceps});
      expect(r.unrecognizedExercises, isEmpty);
    });

    test('unknown ids and cardio are reported as unrecognized, not guessed', () {
      MuscleTargets? resolver(int id) => switch (id) {
            900 => MuscleTargets.none, // e.g. a cardio custom exercise
            _ => kBuiltInExerciseMuscles[id],
          };
      final r = computeMuscleSummary(
        workout([
          log(999999, [s()], name: 'Deleted exercise'),
          log(900, [s()], name: 'Treadmill'),
          log(barbellCurl, [s()]),
        ]),
        resolver: resolver,
      );
      expect(r.primary, {Muscle.biceps});
      expect(r.unrecognizedExercises, ['Deleted exercise', 'Treadmill']);
    });

    test('workout with no recognized muscles has no muscles', () {
      final r = computeMuscleSummary(
        workout([log(999999, [s()], name: 'Mystery')]),
        resolver: (_) => null,
      );
      expect(r.hasMuscles, isFalse);
      expect(r.unrecognizedExercises, ['Mystery']);
    });

    test('empty workout', () {
      final r = computeMuscleSummary(workout(const []));
      expect(r.hasMuscles, isFalse);
      expect(r.setsPerMuscle, isEmpty);
      expect(r.unrecognizedExercises, isEmpty);
    });

    test('custom exercises resolve through the injected resolver', () {
      final custom = ExerciseModel(
        id: 1000001,
        name: 'My Leg Thing',
        category: WorkoutCategory.legs,
        workoutImage: '',
        secondaryMuscles: const ['Lower back', 'nonsense'],
        isCustom: true,
      );
      final r = computeMuscleSummary(
        workout([log(custom.id, [s(), s()])]),
        resolver: (id) => id == custom.id ? muscleTargetsForCustom(custom) : null,
      );
      expect(r.primary, {Muscle.quads, Muscle.hamstrings, Muscle.glutes, Muscle.calves});
      expect(r.secondary, {Muscle.lowerBack});
      expect(r.setsPerMuscle[Muscle.lowerBack], 2);
    });
  });

  group('custom exercises', () {
    ExerciseModel custom(WorkoutCategory c, [List<String> secondary = const []]) => ExerciseModel(
          id: 1000000,
          name: 'Custom',
          category: c,
          workoutImage: '',
          secondaryMuscles: secondary,
          isCustom: true,
        );

    test('the broad category is the primary fallback', () {
      expect(muscleTargetsForCustom(custom(WorkoutCategory.legs)).primary,
          {Muscle.quads, Muscle.hamstrings, Muscle.glutes, Muscle.calves});
      expect(muscleTargetsForCustom(custom(WorkoutCategory.shoulders)).primary,
          {Muscle.frontDelts, Muscle.sideDelts, Muscle.rearDelts});
      expect(muscleTargetsForCustom(custom(WorkoutCategory.chest)).primary, {Muscle.chest});
      expect(muscleTargetsForCustom(custom(WorkoutCategory.cardio)).isEmpty, isTrue);
    });

    test('every category has a fallback entry', () {
      expect(kCategoryFallbackMuscles.keys.toSet(), WorkoutCategory.values.toSet());
    });

    test('recognized secondary names match case/punctuation-insensitively', () {
      final t = muscleTargetsForCustom(
        custom(WorkoutCategory.chest, ['Triceps', ' front-delts ', 'SIDE DELTS']),
      );
      expect(t.secondary, {Muscle.triceps, Muscle.frontDelts, Muscle.sideDelts});
    });

    test('unrecognized secondary names are ignored', () {
      final t = muscleTargetsForCustom(
        custom(WorkoutCategory.bicepes, ['brachialis?', 'the pump', '']),
      );
      expect(t.primary, {Muscle.biceps});
      expect(t.secondary, isEmpty);
    });

    test('a typed secondary that is already primary stays primary only', () {
      final t = muscleTargetsForCustom(custom(WorkoutCategory.triceps, ['triceps', 'chest']));
      expect(t.primary, {Muscle.triceps});
      expect(t.secondary, {Muscle.chest});
    });

    test('musclesForName', () {
      expect(musclesForName('Lats'), {Muscle.lats});
      expect(musclesForName('upper back'), {Muscle.traps});
      expect(musclesForName('calf'), {Muscle.calves});
      expect(musclesForName('pinky toe'), isEmpty);
    });
  });

  test('workingSetCount excludes warm-ups only', () {
    expect(
      workingSetCount(log(1, [s(type: SetType.warmup), s(), s(type: SetType.dropset)])),
      2,
    );
  });
}
