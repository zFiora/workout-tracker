import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';

/// Local store for user-created exercises.
///
/// **ID strategy:** custom ids start at [_idBase] (1,000,000), far above the
/// built-in 1..N range, so a custom exercise can never collide with a built-in
/// and every place that keys on `int` exerciseId (templates, session logs,
/// history) works unchanged.
///
/// Persistence is a Hive `Box<String>` of JSON keyed by the exercise id, and
/// an in-memory cache keeps [all] synchronous (so [ExercisesViewModel.all] can
/// stay a cheap static getter). Deleting a custom exercise only removes it from
/// the catalog — completed workouts store their own name/icon snapshot in
/// `ExerciseLog`, so history is never affected.
class CustomExercisesRepository {
  CustomExercisesRepository._();
  static final CustomExercisesRepository I = CustomExercisesRepository._();

  static const boxName = 'customExercisesBox';
  static const _idBase = 1000000;

  Box<String> get _box => Hive.box<String>(boxName);

  List<ExerciseModel> _cache = const [];
  List<ExerciseModel> get all => _cache;

  /// True for ids in the reserved custom range.
  static bool isCustomId(int id) => id >= _idBase;

  /// Load the cache from Hive. Call once in `main()` after opening the box.
  void load() {
    _cache = _readAll();
  }

  List<ExerciseModel> _readAll() {
    final out = <ExerciseModel>[];
    for (final raw in _box.values) {
      try {
        out.add(ExerciseModel.fromJson(
            jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {
        // skip a corrupt row rather than crash the catalog
      }
    }
    out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return out;
  }

  int _nextId() {
    var maxId = _idBase - 1;
    for (final e in _cache) {
      if (e.id > maxId) maxId = e.id;
    }
    return maxId + 1;
  }

  /// Creates a custom exercise (a new reserved id is assigned) and returns it.
  Future<ExerciseModel> create(ExerciseModel draft) async {
    final withId = ExerciseModel(
      id: _nextId(),
      name: draft.name,
      category: draft.category,
      workoutImage: draft.workoutImage,
      equipment: draft.equipment,
      secondaryMuscles: draft.secondaryMuscles,
      instructions: draft.instructions,
      tips: draft.tips,
      commonMistakes: draft.commonMistakes,
      difficulty: draft.difficulty,
      isCustom: true,
    );
    await _box.put(withId.id.toString(), jsonEncode(withId.toJson()));
    _cache = _readAll();
    return withId;
  }

  Future<void> update(ExerciseModel exercise) async {
    if (!isCustomId(exercise.id)) return; // never touch built-ins
    await _box.put(exercise.id.toString(), jsonEncode(exercise.toJson()));
    _cache = _readAll();
  }

  /// Removes a custom exercise from the catalog. History is untouched (it
  /// stores its own name/icon snapshot per set).
  Future<void> delete(int id) async {
    if (!isCustomId(id)) return;
    await _box.delete(id.toString());
    _cache = _readAll();
  }

  ExerciseModel? byId(int id) {
    for (final e in _cache) {
      if (e.id == id) return e;
    }
    return null;
  }
}
