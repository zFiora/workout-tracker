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

/// Reference implementation of the intended streak rule.
///
/// IMPORTANT: the streak shown in the app is **server-owned** (the client
/// reads `currentStreak`/`bestStreak` from the backend). This calculator is a
/// canonical, tested reference for the intended rule — the backend must
/// implement the same behaviour. It is not currently on the live display path.
///
/// The rule:
///   • A streak counts distinct **workout days** in the current run.
///   • Each new calendar day with a completed workout adds 1 (multiple
///     workouts on the same day count once — no double increment).
///   • The run stays alive while **consecutive** workouts are **less than 48h**
///     apart in elapsed time. A gap of **48h or more** breaks it, and the next
///     workout starts a fresh run at 1.
///   • The current streak is only "alive" if less than 48h have elapsed since
///     the most recent workout relative to [now]; otherwise it's 0 (lost) while
///     the best streak is preserved.
///
/// This is elapsed-time based, not pure calendar arithmetic: e.g. two workouts
/// 47h59m apart continue the run even if a calendar day was skipped between
/// them, whereas 48h01m apart breaks it.
class StreakCalculator {
  /// A gap of this much or more between consecutive workouts breaks the run.
  static const breakThreshold = Duration(hours: 48);

  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  /// [dates]: completed-workout timestamps (any order, duplicates allowed).
  /// [now]: reference "current time" (defaults to DateTime.now()).
  static StreakInfo compute(Iterable<DateTime> dates, {DateTime? now}) {
    final ts = dates.toList()..sort(); // ascending by timestamp
    if (ts.isEmpty) return const StreakInfo(current: 0, best: 0);

    final nowT = now ?? DateTime.now();

    var bestCount = 0;
    var runDayCount = 0;
    DateTime? runLastDay; // last distinct calendar day counted in this run
    DateTime? runStartDay; // first calendar day of the current run
    DateTime? prevTs;

    for (final t in ts) {
      if (prevTs == null) {
        runDayCount = 1;
        runLastDay = _dayOf(t);
        runStartDay = _dayOf(t);
      } else if (t.difference(prevTs) >= breakThreshold) {
        // 48h+ since the previous workout → the old run ends here.
        bestCount = max(bestCount, runDayCount);
        runDayCount = 1;
        runLastDay = _dayOf(t);
        runStartDay = _dayOf(t);
      } else {
        // Same run: only count a genuinely new calendar day.
        final d = _dayOf(t);
        if (d != runLastDay) {
          runDayCount += 1;
          runLastDay = d;
        }
      }
      prevTs = t;
    }
    bestCount = max(bestCount, runDayCount);

    final lastTs = ts.last;
    // Current run is lost once 48h+ have elapsed since the last workout.
    final alive = nowT.difference(lastTs) < breakThreshold;
    final current = alive ? runDayCount : 0;

    return StreakInfo(
      current: current,
      best: bestCount,
      lastWorkoutDate: _dayOf(lastTs),
      currentRunStartedOn: alive ? runStartDay : null,
    );
  }
}
