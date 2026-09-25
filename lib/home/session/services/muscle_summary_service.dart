import 'package:workout_tracker/home/exercises/custom_exercises_repository.dart';
import 'package:workout_tracker/home/exercises/exerciesesList.dart';
import 'package:workout_tracker/home/exercises/exercise_muscle_map.dart';
import 'package:workout_tracker/home/exercises/models/muscle.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

/// Looks up the muscles for an exercise id; null when the id is unknown
/// (e.g. a deleted custom exercise).
typedef MuscleTargetsResolver = MuscleTargets? Function(int exerciseId);

/// Muscles worked in one workout. Pure data — no Flutter imports — so it can
/// be computed for a just-saved workout or any [WorkoutHistoryEntry] later.
class MuscleSummary {
  const MuscleSummary({
    required this.primary,
    required this.secondary,
    required this.setsPerMuscle,
    required this.unrecognizedExercises,
  });

  static const empty = MuscleSummary(
    primary: {},
    secondary: {},
    setsPerMuscle: {},
    unrecognizedExercises: [],
  );

  /// Union of every contributing exercise's primary muscles.
  final Set<Muscle> primary;

  /// Union of secondary muscles, minus anything in [primary].
  final Set<Muscle> secondary;

  /// Working sets (work + drop sets) that involved each highlighted muscle,
  /// as primary or secondary.
  final Map<Muscle, int> setsPerMuscle;

  /// Names of exercises that had working sets but no muscle data (cardio,
  /// deleted custom exercises, unknown ids). Each name listed once.
  final List<String> unrecognizedExercises;

  bool get hasMuscles => primary.isNotEmpty || secondary.isNotEmpty;

  /// Muscles are stored by enum *name* (not index) so reordering/adding
  /// [Muscle] values never corrupts saved summaries; names this build doesn't
  /// know are skipped on read.
  Map<String, dynamic> toJson() => {
        'primary': [for (final m in Muscle.values) if (primary.contains(m)) m.name],
        'secondary': [for (final m in Muscle.values) if (secondary.contains(m)) m.name],
        'setsPerMuscle': {
          for (final e in setsPerMuscle.entries) e.key.name: e.value,
        },
        'unrecognizedExercises': unrecognizedExercises,
      };

  factory MuscleSummary.fromJson(Map<String, dynamic> json) {
    Muscle? parse(Object? name) => Muscle.values.asNameMap()[name];
    Set<Muscle> parseSet(Object? raw) => {
          for (final n in (raw as List? ?? const [])) ?parse(n),
        };
    final primary = parseSet(json['primary']);
    return MuscleSummary(
      primary: primary,
      // Re-assert the invariant on read in case stored data was hand-edited.
      secondary: parseSet(json['secondary'])..removeAll(primary),
      setsPerMuscle: {
        for (final e in (json['setsPerMuscle'] as Map? ?? const {}).entries)
          if (parse(e.key) case final m?) m: (e.value as num).toInt(),
      },
      unrecognizedExercises:
          (json['unrecognizedExercises'] as List? ?? const []).cast<String>(),
    );
  }
}

/// Default resolver: the built-in table, then the user's custom exercises.
MuscleTargets? resolveMuscleTargets(int exerciseId) {
  if (!CustomExercisesRepository.isCustomId(exerciseId)) {
    return kBuiltInExerciseMuscles[exerciseId];
  }
  final exercise = ExercisesViewModel.byId(exerciseId);
  return exercise == null ? null : muscleTargetsForCustom(exercise);
}

/// Warm-ups don't count toward muscles worked; work and drop sets do.
int workingSetCount(ExerciseLog log) =>
    log.sets.where((s) => s.type != SetType.warmup).length;

/// Computes the muscle summary for [entry].
///
/// Only exercises with at least one working set contribute. Duplicate
/// entries for the same exercise id are merged. Primary always wins over
/// secondary.
MuscleSummary computeMuscleSummary(
  WorkoutHistoryEntry entry, {
  MuscleTargetsResolver resolver = resolveMuscleTargets,
}) {
  // Merge duplicate exercise entries: id → (working sets, first name seen).
  final setsByExercise = <int, int>{};
  final nameByExercise = <int, String>{};
  for (final log in entry.logs) {
    final sets = workingSetCount(log);
    if (sets == 0) continue;
    setsByExercise.update(log.exerciseId, (n) => n + sets, ifAbsent: () => sets);
    nameByExercise.putIfAbsent(log.exerciseId, () => log.exerciseName);
  }

  final primary = <Muscle>{};
  final secondary = <Muscle>{};
  final setsPerMuscle = <Muscle, int>{};
  final unrecognized = <String>[];

  setsByExercise.forEach((exerciseId, sets) {
    final targets = resolver(exerciseId);
    if (targets == null || targets.isEmpty) {
      unrecognized.add(nameByExercise[exerciseId]!);
      return;
    }
    primary.addAll(targets.primary);
    secondary.addAll(targets.secondary);
    for (final m in {...targets.primary, ...targets.secondary}) {
      setsPerMuscle.update(m, (n) => n + sets, ifAbsent: () => sets);
    }
  });

  secondary.removeAll(primary);

  return MuscleSummary(
    primary: primary,
    secondary: secondary,
    setsPerMuscle: setsPerMuscle,
    unrecognizedExercises: unrecognized,
  );
}
