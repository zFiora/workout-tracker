// lib/features/streak/streak_calculator.dart
import 'dart:math';

class StreakInfo {
  final int current;
  final int best;
  final DateTime? lastWorkoutDate;
  final DateTime? currentRunStartedOn;

  const StreakInfo({
    required this.current,
    required this.best,
    this.lastWorkoutDate,
    this.currentRunStartedOn,
  });
}

/// Your rule: reset when TWO full days pass with no workout.
/// That is: a gap of 3 or more calendar days between workout dates breaks the run.
class StreakCalculator {
  /// dates: finished-workout timestamps (any order, duplicates allowed)
  /// now: usually DateTime.now()
  static StreakInfo compute(Iterable<DateTime> dates, {DateTime? now}) {
    final today = (now ?? DateTime.now());

    // 1) Reduce to unique calendar days, sorted ascending.
    final uniqueDays = <DateTime>{};
    for (final d in dates) {
      uniqueDays.add(DateTime(d.year, d.month, d.day)); // strip time
    }
    final days = uniqueDays.toList()..sort();

    if (days.isEmpty) {
      return const StreakInfo(current: 0, best: 0);
    }

    // 2) Best streak: longest run where gaps between consecutive days < 3.
    var best = 0;
    var run = 0;
    for (var i = 1; i < days.length; i++) {
      final gap = days[i].difference(days[i - 1]).inDays;
      if (gap >= 3) {
        run = 1; // reset run
      } else {
        run += 1;
        best = max(best, run);
      }
    }

    // 3) Current streak: must end close enough to today (gap < 3 from today).
    final last = days.last;
    final gapToToday = DateTime(today.year, today.month, today.day)
        .difference(last)
        .inDays; // 0=today workout, 1=yesterday, 2=the day before yesterday, 3+=reset

    if (gapToToday >= 3) {
      return StreakInfo(current: 0, best: best, lastWorkoutDate: last);
    }

    // Count tail run backwards while gaps < 3
    var current = 1;
    var runStart = last;
    for (var i = days.length - 1; i > 0; i--) {
      final gap = days[i].difference(days[i - 1]).inDays;
      if (gap >= 3) break;
      current += 1;
      runStart = days[i - 1];
    } 

    return StreakInfo(
      current: current,
      best: best,
      lastWorkoutDate: last,
      currentRunStartedOn: runStart,
    );
  }
}
