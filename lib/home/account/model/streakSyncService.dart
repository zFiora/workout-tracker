import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';

class StreakSyncService {
  final PocketBase pb;
  final String userId; // NOTE: collection == 'users'

  StreakSyncService({
    required this.pb,
    required this.userId, required String profileId,
  });

  /// Ensures server streak reflects "reset after 2 missed days".
  /// Call this on app start (or whenever the app becomes active).
  /// If the last workout was ≥ 3 days ago, sets currentStreak = 0.
  Future<void> normalizeForToday(DateTime now) async {
    final today = _dayOnly(now);

    final rec = await pb.collection('users').getOne(userId);

    final int serverCurrent = rec.getIntValue('currentStreak');
    final String lastIso = rec.getStringValue('lastWorkoutDate');
    final DateTime? last = lastIso.isEmpty ? null : DateTime.tryParse(lastIso);
    final DateTime? lastDay = last == null ? null : _dayOnly(last);

    // If never trained, nothing to reset
    if (lastDay == null) return;

    final gap = today.difference(lastDay).inDays; // 0=today, 1=yesterday, 2=day before, 3+=missed 2 full days

    if (gap >= 3 && serverCurrent != 0) {
      // Reset current to 0 but keep best as-is
      await pb.collection('users').update(userId, body: {
        'currentStreak': 0,
        // don't change bestStreak
        // don't touch streakRunStartedOn
        // don't change lastWorkoutDate (it's historical)
      });
      if (kDebugMode) {
        print('[StreakSync] normalize: gap=$gap -> reset currentStreak=0');
      }
    } else {
      if (kDebugMode) {
        print('[StreakSync] normalize: no reset needed (gap=$gap)');
      }
    }
  }

  /// Call this AFTER saving the first finished session of the day locally.
  /// Idempotent: if today is already counted on server, it no-ops.
  /// Applies your rule: reset if gap ≥ 3; else increment.
  Future<void> bumpIfFirstWorkoutToday(DateTime now) async {
    final today = _dayOnly(now);

    // Read current server snapshot
    final rec = await pb.collection('users').getOne(userId);

    final int serverCurrent = rec.getIntValue('currentStreak');
    final int serverBest    = rec.getIntValue('bestStreak');

    final String lastIso = rec.getStringValue('lastWorkoutDate');
    final DateTime? last = lastIso.isEmpty ? null : DateTime.tryParse(lastIso);
    final DateTime? lastDay = last == null ? null : _dayOnly(last);

    final String runStartIso = rec.getStringValue('streakRunStartedOn');
    DateTime? runStart = runStartIso.isEmpty ? null : DateTime.tryParse(runStartIso);

    // If lastWorkoutDate is already today, do nothing (already bumped)
    if (lastDay != null && lastDay == today) {
      if (kDebugMode) print('[StreakSync] bump: already counted today; skip');
      return;
    }

    // Compute new streak based on gap
    int newCurrent;
    if (lastDay == null) {
      // First ever workout
      newCurrent = 1;
      runStart   = today;
    } else {
      final gap = today.difference(lastDay).inDays; // 1=yesterday, 2=day before, 3+=missed 2 full days
      if (gap >= 3) {
        // Missed too many days -> reset to 1 (new run)
        newCurrent = 1;
        runStart   = today;
      } else {
        // Continue the run
        newCurrent = serverCurrent + 1;
        runStart ??= lastDay; // carry the existing run start if present
      }
    }

    final int newBest = (newCurrent > serverBest) ? newCurrent : serverBest;

    // Write back
    await pb.collection('users').update(userId, body: {
      'currentStreak': newCurrent,
      'bestStreak': newBest,
      'lastWorkoutDate': today.toIso8601String(),
      'streakRunStartedOn': (runStart ?? today).toIso8601String(),
    });

    if (kDebugMode) {
      print('[StreakSync] bump OK -> current=$newCurrent best=$newBest last=$today runStart=$runStart');
    }
  }

  // ---- helpers ----
  DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
