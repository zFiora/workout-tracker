import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:workout_tracker/common/widgets/muscle_map/muscle_overlay.dart';
import 'package:workout_tracker/home/session/recap/progress_photo_store.dart';
import 'package:workout_tracker/home/session/recap/workout_recap.dart';

/// Local-only store of [WorkoutRecap]s, keyed by `WorkoutHistoryEntry.id`.
///
/// Deliberately separate from `historyBox`/`WorkoutHistoryEntry`: that model
/// is Hive-typed *and* is the sync payload (`toJson` is pushed to the API), so
/// adding fields there would change the Hive schema and upload the summary.
/// Values are JSON strings, like `customExercisesBox`, so no adapter is needed.
class WorkoutRecapStore {
  WorkoutRecapStore({Box<String>? box, ProgressPhotoStore? photos})
    : _explicitBox = box,
      _photos = photos ?? ProgressPhotoStore.I;

  static final WorkoutRecapStore I = WorkoutRecapStore();

  static const boxName = 'workoutRecapsBox';

  final Box<String>? _explicitBox;
  final ProgressPhotoStore _photos;

  Box<String> get _box => _explicitBox ?? Hive.box<String>(boxName);

  bool get _available => _explicitBox != null || Hive.isBoxOpen(boxName);

  /// The saved recap for [workoutId], or null for workouts saved before this
  /// feature (or if the stored value can't be read).
  WorkoutRecap? get(String workoutId) {
    if (workoutId.isEmpty || !_available) return null;
    final raw = _box.get(workoutId);
    if (raw == null) return null;
    try {
      return WorkoutRecap.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[WorkoutRecapStore] unreadable recap for $workoutId: $e');
      return null;
    }
  }

  Future<void> put(WorkoutRecap recap) async {
    if (recap.workoutId.isEmpty) return;
    await _box.put(recap.workoutId, jsonEncode(recap.toJson()));
  }

  /// Attaches (or with null, detaches) a progress photo, deleting the file it
  /// replaces. Returns the updated recap.
  Future<WorkoutRecap> setPhoto(WorkoutRecap recap, String? fileName) async {
    final previous = recap.photoFileName;
    final updated = recap.withPhoto(fileName);
    await put(updated);
    if (previous != null && previous != fileName) {
      await _photos.delete(previous);
    }
    return updated;
  }

  /// Saves how the overlay sits on the photo. Only the config changes; the
  /// photo file is untouched.
  Future<WorkoutRecap> setOverlay(
    WorkoutRecap recap,
    OverlayConfig config,
  ) async {
    final updated = recap.withOverlay(config);
    await put(updated);
    return updated;
  }

  /// Removes recaps (and their photos) whose workout no longer exists
  /// locally. Run at startup rather than on every history delete so that the
  /// History "Undo" (which re-saves the same workout id) doesn't lose them.
  Future<int> pruneOrphans(Set<String> liveWorkoutIds) async {
    var removed = 0;
    for (final key in _box.keys.cast<String>().toList()) {
      if (liveWorkoutIds.contains(key)) continue;
      final photo = get(key)?.photoFileName;
      await _box.delete(key);
      if (photo != null) await _photos.delete(photo);
      removed++;
    }
    return removed;
  }
}
