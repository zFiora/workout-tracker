// viewmodels/workout_session_view_model.dart
import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:workout_tracker/home/exercises/exerciesesList.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

class PrHit {
  final int exerciseId;
  final DateTime performedAt;
  final double weight;
  final int reps;
  final String kind; // "bestWeight"

  const PrHit({
    required this.exerciseId,
    required this.performedAt,
    required this.weight,
    required this.reps,
    required this.kind,
  });

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'performedAt': performedAt.toIso8601String(),
    'weight': weight,
    'reps': reps,
    'kind': kind,
  };
}

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
  final Map<String, DateTime> _plannedToPerformedTs = {};

  /// PR hits keyed by "exerciseId:timestampMs"
  final Map<String, PrHit> _prHits = {};

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
  UnmodifiableMapView<String, PrHit> get prHits => UnmodifiableMapView(_prHits);

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

  // ---------- PR helpers ----------

  String _prKey(int exerciseId, DateTime ts) =>
      '$exerciseId:${ts.millisecondsSinceEpoch}';

  void clearPrHits() {
    _prHits.clear();
    notifyListeners();
  }

  PrHit? prHitForPlannedRow({required int exerciseId, required int index}) {
    final ts = _plannedToPerformedTs['$exerciseId:$index'];
    if (ts == null) return null;
    return _prHits[_prKey(exerciseId, ts)];
  }

  double _bestWeightAllTime({
    required int exerciseId,
    required List<WorkoutHistoryEntry> history,
  }) {
    double best = 0;
    for (final entry in history) {
      for (final log in entry.logs) {
        if (log.exerciseId != exerciseId) continue;
        for (final s in log.sets) {
          if (s.weight > best) best = s.weight;
        }
      }
    }
    return best;
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

    log.sets[index].type = type;
    notifyListeners();
  }

  void removeSet(int exerciseId, int index) {
    final log = _logs[exerciseId];
    if (log == null) return;
    if (index < 0 || index >= log.sets.length) return;

    final removed = log.sets.removeAt(index);
    _plannedToPerformedTs.removeWhere((_, ts) => ts == removed.timestamp);

    notifyListeners();
  }

  // ---------- Planned sets ----------

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

    _plannedToPerformedTs.removeWhere(
      (key, _) => key.startsWith('$exerciseId:'),
    );
    log.plannedSets.clear();
    notifyListeners();
  }

  void addPlannedSetRow({
    required int exerciseId,
    SetType type = SetType.work,
  }) {
    final log = _logs[exerciseId];
    if (log == null) return;

    double? w;
    int? r;

    for (int i = log.plannedSets.length - 1; i >= 0; i--) {
      final p = log.plannedSets[i];
      if (p.weight != null && p.reps != null) {
        w = p.weight;
        r = p.reps;
        break;
      }
    }

    if (w == null || r == null) {
      if (log.sets.isNotEmpty) {
        final last = log.sets.last;
        w ??= last.weight;
        r ??= last.reps;
      }
    }

    log.plannedSets.add(
      PlannedSet(type: type, weight: w, reps: r, done: false),
    );

    notifyListeners();
  }

  void removePlannedSetRow({required int exerciseId, required int index}) {
    final log = _logs[exerciseId];
    if (log == null) return;
    if (index < 0 || index >= log.plannedSets.length) return;

    if (log.plannedSets[index].done) return;

    _plannedToPerformedTs.remove('$exerciseId:$index');
    _rebuildPlannedMappingKeysForExercise(exerciseId);

    log.plannedSets.removeAt(index);
    notifyListeners();
  }

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

    if (p.done) {
      final key = '$exerciseId:$index';
      final ts = _plannedToPerformedTs[key];

      if (ts != null) {
        final performedIndex = log.sets.indexWhere((s) => s.timestamp == ts);

        if (performedIndex != -1) {
          final w = p.weight;
          final r = p.reps;

          if (w != null && r != null) {
            updatePerformedSet(
              exerciseId: exerciseId,
              index: performedIndex,
              weight: w,
              reps: r,
              type: p.type,
            );
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
    required List<WorkoutHistoryEntry> history,
  }) {
    final log = _logs[exerciseId];
    if (log == null) return;
    if (index < 0 || index >= log.plannedSets.length) return;

    final p = log.plannedSets[index];
    if (p.done) return;

    final w = p.weight;
    final r = p.reps;
    if (w == null || r == null) return;

    final prevBest = _bestWeightAllTime(
      exerciseId: exerciseId,
      history: history,
    );

    p.done = true;

    final ts = DateTime.now();

    log.sets.add(PerformedSet(weight: w, reps: r, timestamp: ts, type: p.type));

    _plannedToPerformedTs['$exerciseId:$index'] = ts;

    // PR hit (best weight)
    if (w > prevBest) {
      final hit = PrHit(
        exerciseId: exerciseId,
        performedAt: ts,
        weight: w,
        reps: r,
        kind: 'bestWeight',
      );
      _prHits[_prKey(exerciseId, ts)] = hit;
    }

    notifyListeners();
  }

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
      final performedIndex = log.sets.indexWhere((s) => s.timestamp == ts);
      if (performedIndex != -1) {
        log.sets.removeAt(performedIndex);
      }
      _prHits.remove(_prKey(exerciseId, ts));
    }

    _plannedToPerformedTs.remove(key);
    notifyListeners();
  }

  void _rebuildPlannedMappingKeysForExercise(int exerciseId) {
    final log = _logs[exerciseId];
    if (log == null) return;

    final entries = <MapEntry<String, DateTime>>[];
    _plannedToPerformedTs.forEach((key, ts) {
      if (key.startsWith('$exerciseId:')) {
        entries.add(MapEntry(key, ts));
      }
    });

    _plannedToPerformedTs.removeWhere(
      (key, _) => key.startsWith('$exerciseId:'),
    );

    for (int i = 0; i < log.plannedSets.length; i++) {
      final p = log.plannedSets[i];
      if (!p.done) continue;

      DateTime? reused;
      for (final e in List<MapEntry<String, DateTime>>.from(entries)) {
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
