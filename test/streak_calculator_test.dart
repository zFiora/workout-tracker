import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/home/account/model/streakCalculator.dart';

/// Fake, fully-controllable clock. Every case pins both the workout timestamps
/// and `now` so the 48h-elapsed rule is tested deterministically (no reliance
/// on the wall clock).
void main() {
  final mon8 = DateTime(2026, 3, 2, 8, 0); // Monday 08:00

  group('StreakCalculator — intended 48h-elapsed rule', () {
    test('no workouts → 0 / 0', () {
      final s = StreakCalculator.compute(const [], now: mon8);
      expect(s.current, 0);
      expect(s.best, 0);
      expect(s.lastWorkoutDate, isNull);
    });

    test('first workout → current 1, best 1', () {
      final s = StreakCalculator.compute([mon8], now: mon8);
      expect(s.current, 1);
      expect(s.best, 1);
      expect(s.lastWorkoutDate, DateTime(2026, 3, 2));
    });

    test('two workouts SAME day count once (no double increment)', () {
      final s = StreakCalculator.compute(
        [mon8, mon8.add(const Duration(hours: 8))], // Mon 08:00 + Mon 16:00
        now: mon8.add(const Duration(hours: 8, minutes: 1)),
      );
      expect(s.current, 1);
      expect(s.best, 1);
    });

    test('24h apart (Mon 08:00 → Tue 08:00) → continues to 2', () {
      final tue8 = mon8.add(const Duration(hours: 24));
      final s = StreakCalculator.compute(
        [mon8, tue8],
        now: tue8.add(const Duration(minutes: 1)),
      );
      expect(s.current, 2);
      expect(s.best, 2);
    });

    test('user example: Mon 08:00 → Tue 07:00 (23h) → continues to 2', () {
      final tue7 = DateTime(2026, 3, 3, 7, 0);
      final s = StreakCalculator.compute(
        [mon8, tue7],
        now: tue7.add(const Duration(minutes: 1)),
      );
      expect(s.current, 2);
    });

    test('47h59m apart (skips a calendar day) still continues to 2', () {
      // Mon 08:00 → Wed 07:59. Tuesday had no workout, but elapsed < 48h.
      final wed759 = mon8.add(const Duration(hours: 47, minutes: 59));
      final s = StreakCalculator.compute(
        [mon8, wed759],
        now: wed759.add(const Duration(minutes: 1)),
      );
      expect(s.current, 2, reason: 'elapsed-time rule, not calendar-consecutive');
      expect(s.best, 2);
    });

    test('EXACTLY 48h apart → BREAKS (48h or more is a break) → restart at 1', () {
      // Boundary flagged in the audit: "48 hours OR MORE" loses the streak,
      // so exactly 48h breaks. Threshold is `>= 48h`.
      final wed8 = mon8.add(const Duration(hours: 48));
      final s = StreakCalculator.compute(
        [mon8, wed8],
        now: wed8.add(const Duration(minutes: 1)),
      );
      expect(s.current, 1, reason: 'exactly 48h breaks and restarts at 1');
      expect(s.best, 1);
    });

    test('user example: Mon 08:00 → Wed 08:01 (48h1m) → breaks, restart at 1', () {
      final wed801 = mon8.add(const Duration(hours: 48, minutes: 1));
      final s = StreakCalculator.compute(
        [mon8, wed801],
        now: wed801.add(const Duration(minutes: 1)),
      );
      expect(s.current, 1);
      expect(s.best, 1);
    });

    test('several consecutive days → counts up (Mon..Fri = 5)', () {
      final days = [
        for (int i = 0; i < 5; i++) mon8.add(Duration(hours: 24 * i)),
      ];
      final s = StreakCalculator.compute(
        days,
        now: days.last.add(const Duration(minutes: 1)),
      );
      expect(s.current, 5);
      expect(s.best, 5);
    });

    test('current streak LOST once 48h elapse since last workout (now-based)', () {
      // Mon,Tue run of 2. Now is Fri → >48h since Tue → current 0, best kept.
      final tue8 = mon8.add(const Duration(hours: 24));
      final s = StreakCalculator.compute(
        [mon8, tue8],
        now: DateTime(2026, 3, 6, 8), // Friday
      );
      expect(s.current, 0, reason: '>48h since last workout loses current');
      expect(s.best, 2, reason: 'best is preserved after a break');
      expect(s.currentRunStartedOn, isNull);
    });

    test('restart after a long gap: old best preserved, new run starts at 1', () {
      final run1 = [
        mon8,
        mon8.add(const Duration(hours: 24)),
        mon8.add(const Duration(hours: 48 - 1)), // Wed 07:00, still run 1 → 3 days
      ];
      final restart = mon8.add(const Duration(days: 10)); // long gap later
      final s = StreakCalculator.compute(
        [...run1, restart],
        now: restart.add(const Duration(minutes: 1)),
      );
      expect(s.current, 1, reason: 'new run restarts at 1');
      expect(s.best, 3, reason: 'best from the earlier 3-day run is kept');
    });

    test('unordered input is handled (sorted internally)', () {
      final tue8 = mon8.add(const Duration(hours: 24));
      final wed8 = mon8.add(const Duration(hours: 47)); // <48h from tue
      final s = StreakCalculator.compute(
        [wed8, mon8, tue8], // deliberately shuffled
        now: wed8.add(const Duration(minutes: 1)),
      );
      expect(s.current, 3);
      expect(s.best, 3);
    });

    test('just under the alive boundary: 47h59m since last → still alive', () {
      final s = StreakCalculator.compute(
        [mon8],
        now: mon8.add(const Duration(hours: 47, minutes: 59)),
      );
      expect(s.current, 1);
    });

    test('exactly 48h since last workout relative to now → lost', () {
      final s = StreakCalculator.compute(
        [mon8],
        now: mon8.add(const Duration(hours: 48)),
      );
      expect(s.current, 0);
      expect(s.best, 1);
    });
  });
}
