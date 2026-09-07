import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:workout_tracker/home/exercises/exerciesesList.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';
import 'package:workout_tracker/home/session/services/session_snapshot_store.dart';
import 'package:workout_tracker/home/session/sessionViewModel.dart';

/// Root-level ChangeNotifier that owns the currently active workout session.
/// Lives for the lifetime of the app so the timer survives navigation.
///
/// Session progress is otherwise only ever held in memory, so it would be
/// lost outright if the app process is killed mid-workout (OS memory
/// pressure, force-close, crash — not just backgrounding). To guard against
/// that, the session is snapshotted to Hive on every structural change and
/// on a periodic autosave via [SessionSnapshotStore], and a matching
/// snapshot found at startup is silently resumed — same session, same
/// elapsed time, sets intact.
class ActiveSessionManager extends ChangeNotifier {
  ActiveSessionManager({SessionSnapshotStore? snapshotStore})
      : _snapshotStore = snapshotStore ?? SessionSnapshotStore() {
    _restore();
  }

  final SessionSnapshotStore _snapshotStore;

  /// Periodic (not debounced) autosave — the session VM's `notifyListeners`
  /// fires every second from its own running ticker, so a "reset the timer
  /// on every change" debounce would never actually elapse. A fixed interval
  /// bounds the staleness window regardless of tick chatter.
  Timer? _autosave;

  WorkoutSessionViewModel? _session;
  List<ExerciseModel> _exercises = [];
  List<int> _originalExerciseIds = [];
  String? _templateId;
  String? _templateName;
  String? _templateIcon;

  // ── getters ──────────────────────────────────────────────────────────────

  WorkoutSessionViewModel? get session => _session;
  bool get hasActiveSession => _session != null;

  List<ExerciseModel> get exercises => List.unmodifiable(_exercises);
  String? get templateId => _templateId;
  String? get templateName => _templateName;
  String? get templateIcon => _templateIcon;

  /// True when exercises were added, removed, or reordered mid-session vs
  /// the template this session started from. Order-sensitive (a straight
  /// `Set` comparison would miss a pure reorder with no add/remove) so a
  /// reorder-only session still triggers the end-of-session template prompt.
  bool get exercisesWereModified {
    if (_session == null) return false;
    final current = _exercises.map((e) => e.id).toList();
    if (current.length != _originalExerciseIds.length) return true;
    for (var i = 0; i < current.length; i++) {
      if (current[i] != _originalExerciseIds[i]) return true;
    }
    return false;
  }

  // ── session lifecycle ─────────────────────────────────────────────────────

  void startSession({
    required String templateId,
    required String templateName,
    required String templateIcon,
    required List<ExerciseModel> exercises,
  }) {
    // tear down any previous session
    _session?.removeListener(_onSessionChanged);
    _session?.cancel();
    _session = null;

    _templateId = templateId;
    _templateName = templateName;
    _templateIcon = templateIcon;
    _exercises = List.of(exercises);
    _originalExerciseIds = exercises.map((e) => e.id).toList();

    final vm = WorkoutSessionViewModel(
      templateId: templateId,
      templateName: templateName,
      templateIcon: templateIcon,
      exerciseIds: exercises.map((e) => e.id).toList(),
    )..start();

    vm.addListener(_onSessionChanged);
    _session = vm;
    notifyListeners();
    _persistNow();
    _startAutosave();
  }

  /// Stops the timer, clears session state, and returns the history entry.
  /// Call BEFORE saving to HistoryViewModel.
  WorkoutHistoryEntry endSession() {
    final s = _session;
    if (s == null) throw StateError('No active session');

    s.removeListener(_onSessionChanged);
    final entry = s.end(); // stops timer; returns WorkoutHistoryEntry

    _session = null;
    _templateId = null;
    _templateName = null;
    _templateIcon = null;
    // keep _exercises / _originalExerciseIds until caller finishes comparing
    notifyListeners();
    _stopAutosave();
    _snapshotStore.clear();
    return entry;
  }

  /// Clears exercise tracking state. Call after handling template-update dialog.
  void clearAfterEnd() {
    _exercises = [];
    _originalExerciseIds = [];
    notifyListeners();
  }

  /// Cancel session without saving.
  void discardSession() {
    _session?.removeListener(_onSessionChanged);
    _session?.cancel();
    _session = null;
    _templateId = null;
    _templateName = null;
    _templateIcon = null;
    _exercises = [];
    _originalExerciseIds = [];
    notifyListeners();
    _stopAutosave();
    _snapshotStore.clear();
  }

  // ── mid-session exercise editing ─────────────────────────────────────────

  void addExerciseToSession(ExerciseModel exercise) {
    if (_session == null) return;
    if (_exercises.any((e) => e.id == exercise.id)) return;
    _exercises = [..._exercises, exercise];
    _session!.addExercise(exercise);
    notifyListeners();
    _persistNow();
  }

  void removeExerciseFromSession(ExerciseModel exercise) {
    if (_session == null) return;
    if (!_exercises.any((e) => e.id == exercise.id)) return;
    _exercises = _exercises.where((e) => e.id != exercise.id).toList();
    _session!.removeExercise(exercise.id);
    notifyListeners();
    _persistNow();
  }

  /// Reorders the session's exercise list. Purely a display/save-order
  /// concern — [WorkoutSessionViewModel.logs] is keyed by exercise id and
  /// doesn't need touching. Uses `ReorderableListView`'s index convention
  /// (`newIndex` is the target index *after* the item is removed from
  /// `oldIndex`).
  void reorderExercise(int oldIndex, int newIndex) {
    if (_session == null) return;
    if (oldIndex < 0 || oldIndex >= _exercises.length) return;
    var target = newIndex;
    if (target > oldIndex) target -= 1;
    if (target < 0 || target >= _exercises.length) return;
    if (target == oldIndex) return;

    final updated = List<ExerciseModel>.of(_exercises);
    final moved = updated.removeAt(oldIndex);
    updated.insert(target, moved);
    _exercises = updated;
    notifyListeners();
    _persistNow();
  }

  // ── crash/kill resilience ───────────────────────────────────────────────

  /// Looks for a session snapshot left by a previous process (app killed
  /// mid-workout) and, if found, silently resumes it — same elapsed time,
  /// same logged sets. Runs once, fired from the constructor.
  Future<void> _restore() async {
    final json = _snapshotStore.read();
    if (json == null) return;

    try {
      final templateId = json['templateId'] as String? ?? '';
      final templateName = json['templateName'] as String? ?? '';
      final templateIcon = json['templateIcon'] as String? ?? '';
      final startedAt = DateTime.parse(json['startedAt'] as String);

      final exerciseIds = (json['exerciseIds'] as List? ?? const [])
          .map((e) => (e as num).toInt())
          .toList();
      final originalExerciseIds =
          (json['originalExerciseIds'] as List? ?? const [])
              .map((e) => (e as num).toInt())
              .toList();

      final logsJson = (json['logs'] as Map?)?.cast<String, dynamic>() ?? {};
      final restoredLogs = <int, ExerciseLog>{
        for (final entry in logsJson.entries)
          int.parse(entry.key):
              ExerciseLog.fromJson(Map<String, dynamic>.from(entry.value as Map)),
      };

      // Exercise catalog is static; a ChangeNotifier-visible list of the
      // resolved models is still needed for mid-session add/remove UI.
      final exercises = <ExerciseModel>[];
      for (final id in exerciseIds) {
        for (final ex in ExercisesViewModel.all) {
          if (ex.id == id) {
            exercises.add(ex);
            break;
          }
        }
      }
      if (exercises.isEmpty) return; // catalog mismatch — nothing to resume

      _templateId = templateId;
      _templateName = templateName;
      _templateIcon = templateIcon;
      _exercises = exercises;
      _originalExerciseIds = originalExerciseIds;

      final vm = WorkoutSessionViewModel(
        templateId: templateId,
        templateName: templateName,
        templateIcon: templateIcon,
        exerciseIds: exercises.map((e) => e.id).toList(),
        restoredLogs: restoredLogs,
      )..start(resumeFrom: startedAt);

      vm.addListener(_onSessionChanged);
      _session = vm;
      notifyListeners();
      _startAutosave();
    } catch (e) {
      debugPrint('[ActiveSessionManager] failed to restore session: $e');
      await _snapshotStore.clear();
    }
  }

  void _startAutosave() {
    _autosave?.cancel();
    _autosave = Timer.periodic(const Duration(seconds: 5), (_) => _persistNow());
  }

  void _stopAutosave() {
    _autosave?.cancel();
    _autosave = null;
  }

  void _persistNow() {
    final s = _session;
    if (s == null) return;
    _snapshotStore.save({
      'templateId': _templateId,
      'templateName': _templateName,
      'templateIcon': _templateIcon,
      'startedAt': (s.startedAt ?? DateTime.now()).toIso8601String(),
      'exerciseIds': _exercises.map((e) => e.id).toList(),
      'originalExerciseIds': _originalExerciseIds,
      'logs': {
        for (final entry in s.logs.entries)
          entry.key.toString(): entry.value.toJson(),
      },
    });
  }

  // ── internal ─────────────────────────────────────────────────────────────

  void _onSessionChanged() => notifyListeners();

  @override
  void dispose() {
    _autosave?.cancel();
    _session?.removeListener(_onSessionChanged);
    _session?.cancel();
    super.dispose();
  }
}
