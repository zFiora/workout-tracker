// viewmodels/workout_session_view_model.dart
import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:workout_tracker/home/exercises/exerciesesList.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

class WorkoutSessionViewModel extends ChangeNotifier {
  final String templateId;
  final String templateName;
  final List<int> exerciseIds;
  final String templateIcon;

  DateTime? _startedAt;
  DateTime? _endedAt;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;

  final Map<int, ExerciseLog> _logs = {};
  final List<ExerciseModel> allExercises = ExercisesViewModel.all;

  /// Maps a planned row (exerciseId:index) to the performed set timestamp created when it was marked done.
  /// This is enough to find & update the performed set later (within this session).
  final Map<String, DateTime> _plannedToPerformedTs = {};

  WorkoutSessionViewModel({
    required this.templateId,
    required this.templateName,
    required this.templateIcon,
    required this.exerciseIds,
  }) {
    for (final id in exerciseIds) {
      final ex = allExercises.firstWhere((e) => e.id == id);

      _logs[id] = ExerciseLog(
        exerciseId: id,
        exerciseName: ex.name,
        exerciseIcon: ex.workoutImage,
      );
    }
  }

  bool get isRunning => _ticker != null;
  Duration get elapsed => _elapsed;
  DateTime? get startedAt => _startedAt;

  UnmodifiableMapView<int, ExerciseLog> get logs => UnmodifiableMapView(_logs);

  // ---------- UI-ready helpers ----------

  String get elapsedText => _format(_elapsed);

  int get totalSets =>
      _logs.values.fold(0, (sum, log) => sum + log.sets.length);

  int get totalWorkSets => _logs.values.fold(
        0,
        (sum, log) => sum + log.sets.where((s) => s.type == SetType.work).length,
      );

  double get totalVolume {
    double v = 0;
    for (final log in _logs.values) {
      for (final s in log.sets) {
        if (s.type != SetType.work) continue;
        v += (s.weight * s.reps);
      }
    }
    return v;
  }

  // ---------- Session lifecycle ----------

  void start() {
    if (isRunning) return;
    _startedAt = DateTime.now();
    _endedAt = null;
    _elapsed = Duration.zero;

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final start = _startedAt;
      if (start == null) return;
      _elapsed = DateTime.now().difference(start);
      notifyListeners();
    });

    notifyListeners();
  }

  WorkoutHistoryEntry end() {
    if (!isRunning) {
      throw StateError('Session not running');
    }

    _ticker?.cancel();
    _ticker = null;

    _endedAt = DateTime.now();
    final start = _startedAt ?? _endedAt!;
    _elapsed = _endedAt!.difference(start);

    final entry = WorkoutHistoryEntry(
      templateIcon: templateIcon,
      templateId: templateId,
      templateName: templateName,
      startedAt: start,
      endedAt: _endedAt!,
      duration: _elapsed,
      logs: _logs.values
          .map(
            (e) => ExerciseLog(
              exerciseId: e.exerciseId,
              sets: List.of(e.sets),
              exerciseIcon: e.exerciseIcon,
              exerciseName: e.exerciseName,
              // plannedSets intentionally not persisted to history
            ),
          )
          .toList(),
    );

    notifyListeners();
    return entry;
  }

  // ---------- Performed sets CRUD ----------

  void addSet({
    required int exerciseId,
    required double weight,
    required int reps,
    SetType type = SetType.work,
  }) {
    final log = _logs[exerciseId];
    if (log == null) return;

    log.sets.add(
      PerformedSet(
        weight: weight,
        reps: reps,
        timestamp: DateTime.now(),
        type: type,
      ),
    );
    notifyListeners();
  }

  /// Edit an existing performed set (replaces the object to support immutable fields).
  void updatePerformedSet({
    required int exerciseId,
    required int index,
    double? weight,
    int? reps,
    SetType? type,
  }) {
    final log = _logs[exerciseId];
    if (log == null) return;
    if (index < 0 || index >= log.sets.length) return;

    final old = log.sets[index];
    final updated = PerformedSet(
      weight: weight ?? old.weight,
      reps: reps ?? old.reps,
      timestamp: old.timestamp,
      type: type ?? old.type,
    );

    log.sets[index] = updated;
    notifyListeners();
  }

  void updateSetType({
    required int exerciseId,
    required int index,
    required SetType type,
  }) {
    final log = _logs[exerciseId];
    if (log == null) return;
    if (index < 0 || index >= log.sets.length) return;

    // type is mutable in your model; keep it.
    log.sets[index].type = type;
    notifyListeners();
  }

  void removeSet(int exerciseId, int index) {
    final log = _logs[exerciseId];
    if (log == null) return;
    if (index < 0 || index >= log.sets.length) return;

    final removed = log.sets.removeAt(index);

    // Clean any mapping pointing to this timestamp (optional safety).
    _plannedToPerformedTs.removeWhere((_, ts) => ts == removed.timestamp);

    notifyListeners();
  }

  // ---------- Planned sets (your checklist UI) ----------

  void loadPlannedSetsFromLastWorkout({
    required int exerciseId,
    required List<PerformedSet> lastSets,
  }) {
    final log = _logs[exerciseId];
    if (log == null) return;
    if (lastSets.isEmpty) return;

    if (log.plannedSets.isNotEmpty) return;

    log.plannedSets
      ..clear()
      ..addAll(
        lastSets.map(
          (s) => PlannedSet(
            type: s.type,
            weight: s.weight,
            reps: s.reps,
            done: false,
          ),
        ),
      );

    notifyListeners();
  }

  void clearPlannedSets(int exerciseId) {
    final log = _logs[exerciseId];
    if (log == null) return;

    // Also clean mappings for this exercise.
    _plannedToPerformedTs.removeWhere((key, _) => key.startsWith('$exerciseId:'));

    log.plannedSets.clear();
    notifyListeners();
  }

  /// Adds a planned row and auto-fills weight/reps from the last set in THIS session.
  /// Priority:
  /// 1) last planned row with non-null values
  /// 2) last performed set
  /// 3) nulls (user fills)
  void addPlannedSetRow({
    required int exerciseId,
    SetType type = SetType.work,
  }) {
    final log = _logs[exerciseId];
    if (log == null) return;

    double? w;
    int? r;

    // 1) last planned with values
    for (int i = log.plannedSets.length - 1; i >= 0; i--) {
      final p = log.plannedSets[i];
      if (p.weight != null && p.reps != null) {
        w = p.weight;
        r = p.reps;
        break;
      }
    }

    // 2) fallback: last performed
    if (w == null || r == null) {
      if (log.sets.isNotEmpty) {
        final last = log.sets.last;
        w ??= last.weight;
        r ??= last.reps;
      }
    }

    log.plannedSets.add(
      PlannedSet(
        type: type,
        weight: w,
        reps: r,
        done: false,
      ),
    );

    notifyListeners();
  }

  void removePlannedSetRow({
    required int exerciseId,
    required int index,
  }) {
    final log = _logs[exerciseId];
    if (log == null) return;
    if (index < 0 || index >= log.plannedSets.length) return;

    // If it was done, you can decide whether to allow deleting it + also deleting its performed set.
    // For now: keep your safety rule.
    if (log.plannedSets[index].done) return;

    // Clean mapping key(s) after this index (because indices shift).
    _plannedToPerformedTs.remove('$exerciseId:$index');
    _rebuildPlannedMappingKeysForExercise(exerciseId);

    log.plannedSets.removeAt(index);
    notifyListeners();
  }

  /// Updates a planned set.
  /// - If NOT done: edits the row as usual.
  /// - If done: edits the row AND updates the corresponding performed set too (fix mistakes).
  void updatePlannedSet({
    required int exerciseId,
    required int index,
    double? weight,
    int? reps,
    SetType? type,
  }) {
    final log = _logs[exerciseId];
    if (log == null) return;
    if (index < 0 || index >= log.plannedSets.length) return;

    final p = log.plannedSets[index];

    if (type != null) p.type = type;
    if (weight != null) p.weight = weight;
    if (reps != null) p.reps = reps;

    // If it's done, update the performed set created by this planned row.
    if (p.done) {
      final key = '$exerciseId:$index';
      final ts = _plannedToPerformedTs[key];

      if (ts != null) {
        final performedIndex =
            log.sets.indexWhere((s) => s.timestamp == ts);

        if (performedIndex != -1) {
          final w = p.weight;
          final r = p.reps;

          // Only update if we have valid values.
          if (w != null && r != null) {
            updatePerformedSet(
              exerciseId: exerciseId,
              index: performedIndex,
              weight: w,
              reps: r,
              type: p.type,
            );
            // updatePerformedSet notifies already, so return early.
            return;
          }
        }
      }
    }

    notifyListeners();
  }

  void markPlannedSetDone({
    required int exerciseId,
    required int index,
  }) {
    final log = _logs[exerciseId];
    if (log == null) return;
    if (index < 0 || index >= log.plannedSets.length) return;

    final p = log.plannedSets[index];
    if (p.done) return;

    final w = p.weight;
    final r = p.reps;
    if (w == null || r == null) return;

    p.done = true;

    final ts = DateTime.now();

    log.sets.add(
      PerformedSet(
        weight: w,
        reps: r,
        timestamp: ts,
        type: p.type,
      ),
    );

    _plannedToPerformedTs['$exerciseId:$index'] = ts;

    notifyListeners();
  }

  /// Optional: allow undo done (keeps things consistent).
  void undoPlannedSetDone({
    required int exerciseId,
    required int index,
    bool removePerformed = true,
  }) {
    final log = _logs[exerciseId];
    if (log == null) return;
    if (index < 0 || index >= log.plannedSets.length) return;

    final p = log.plannedSets[index];
    if (!p.done) return;

    final key = '$exerciseId:$index';
    final ts = _plannedToPerformedTs[key];

    p.done = false;

    if (removePerformed && ts != null) {
      final performedIndex =
          log.sets.indexWhere((s) => s.timestamp == ts);
      if (performedIndex != -1) {
        log.sets.removeAt(performedIndex);
      }
    }

    _plannedToPerformedTs.remove(key);
    notifyListeners();
  }

  void _rebuildPlannedMappingKeysForExercise(int exerciseId) {
    // If you delete planned rows, indices shift. This rebuild keeps the map sane.
    // We rebuild only for this exercise.
    final log = _logs[exerciseId];
    if (log == null) return;

    final entries = <MapEntry<String, DateTime>>[];
    _plannedToPerformedTs.forEach((key, ts) {
      if (key.startsWith('$exerciseId:')) {
        entries.add(MapEntry(key, ts));
      }
    });

    // Clear old keys for this exercise
    _plannedToPerformedTs.removeWhere((key, _) => key.startsWith('$exerciseId:'));

    // Re-add sequentially for done rows where we can still match by timestamp in performed sets.
    // NOTE: This is best-effort; if you rely heavily on deleting rows, consider persisting an ID on PlannedSet.
    for (int i = 0; i < log.plannedSets.length; i++) {
      final p = log.plannedSets[i];
      if (!p.done) continue;

      // Try to reuse an existing ts that still exists in performed sets.
      DateTime? reused;
      for (final e in entries) {
        final ts = e.value;
        if (log.sets.any((s) => s.timestamp == ts)) {
          reused = ts;
          entries.remove(e);
          break;
        }
      }

      if (reused != null) {
        _plannedToPerformedTs['$exerciseId:$i'] = reused;
      }
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _format(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
