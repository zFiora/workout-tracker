import 'package:shared_preferences/shared_preferences.dart';

/// Local, per-tutorial persistence for the coach-mark system.
///
/// Each tutorial is tracked independently by an integer *version* under the key
/// `tutorial_<id>_version` in [SharedPreferences] (the same local store
/// `AppManager`/`RestTimerManager` already use — no Hive box, no backend).
///
/// A tutorial is shown when the stored version is lower than the tutorial's
/// current version. This is deliberately a version, not a bool: bumping one
/// tutorial's version re-shows only that tutorial (e.g. after adding a new
/// step for a new feature), and never resets any of the others.
class TutorialStore {
  const TutorialStore();

  static const String keyPrefix = 'tutorial_';
  static String storageKey(String id) => '$keyPrefix${id}_version';

  /// True when [id] has never been seen at [version] or higher.
  Future<bool> shouldShow(String id, int version) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getInt(storageKey(id)) ?? 0;
    return seen < version;
  }

  /// Records that [id] has been seen at [version]. Monotonic — never lowers a
  /// stored version, so an older tutorial build can't "un-see" a newer one.
  Future<void> markSeen(String id, int version) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getInt(storageKey(id)) ?? 0;
    if (version > seen) {
      await prefs.setInt(storageKey(id), version);
    }
  }

  /// The stored version for [id] (0 if never seen). Mostly for tests/debugging.
  Future<int> seenVersion(String id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(storageKey(id)) ?? 0;
  }

  /// Clears [id] so its tutorial will show again — useful for a future
  /// "replay tutorials" affordance or for tests.
  Future<void> reset(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey(id));
  }
}
