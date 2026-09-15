import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_tracker/home/session/rest_timer_manager.dart';
import 'package:workout_tracker/home/session/rest_timer_notification_service.dart';

/// Records what the manager asked the notification layer to do, so we can
/// assert behaviour without any real Android notification delivery.
class FakeRestTimerNotifier implements RestTimerNotifier {
  bool? enabled;
  final List<({Duration remaining, bool paused})> running = [];
  int completeCount = 0;
  int cancelCount = 0;

  @override
  Future<void> setEnabled(bool value) async {
    enabled = value;
    if (!value) await cancel(); // mirrors the real service
  }

  @override
  Future<void> showRunning({
    required Duration remaining,
    required bool paused,
  }) async {
    running.add((remaining: remaining, paused: paused));
  }

  @override
  Future<void> showComplete() async => completeCount++;

  @override
  Future<void> cancel() async => cancelCount++;
}

/// Builds a manager and waits for its async pref load to settle so tests don't
/// race the constructor's `_loadPrefs`.
Future<RestTimerManager> _manager(FakeRestTimerNotifier fake) async {
  final m = RestTimerManager(fake);
  await Future<void>.delayed(const Duration(milliseconds: 10));
  return m;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('formatRestRemaining', () {
    test('90s → 01:30', () {
      expect(formatRestRemaining(const Duration(seconds: 90)), '01:30');
    });
    test('60s → 01:00', () {
      expect(formatRestRemaining(const Duration(seconds: 60)), '01:00');
    });
    test('15s → 00:15', () {
      expect(formatRestRemaining(const Duration(seconds: 15)), '00:15');
    });
    test('0s → 00:00', () {
      expect(formatRestRemaining(Duration.zero), '00:00');
    });
    test('negative remaining clamps to 00:00', () {
      expect(formatRestRemaining(const Duration(seconds: -5)), '00:00');
    });
    test('multi-minute pads correctly (605s → 10:05)', () {
      expect(formatRestRemaining(const Duration(seconds: 605)), '10:05');
    });
  });

  group('preference', () {
    test('defaults to enabled when nothing is stored', () async {
      final fake = FakeRestTimerNotifier();
      final m = await _manager(fake);
      expect(m.notificationsEnabled, isTrue);
      expect(fake.enabled, isTrue); // pushed to the notifier on load
      m.dispose();
    });

    test('a stored disabled value is honoured on load', () async {
      SharedPreferences.setMockInitialValues(
        {'rest_timer_notifications_enabled': false},
      );
      final fake = FakeRestTimerNotifier();
      final m = await _manager(fake);
      expect(m.notificationsEnabled, isFalse);
      expect(fake.enabled, isFalse);
      m.dispose();
    });

    test('disabling persists to the expected key', () async {
      final m = await _manager(FakeRestTimerNotifier());
      await m.setNotificationsEnabled(false);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('rest_timer_notifications_enabled'), isFalse);
      m.dispose();
    });

    test('re-enabling persists true', () async {
      final m = await _manager(FakeRestTimerNotifier());
      await m.setNotificationsEnabled(false);
      await m.setNotificationsEnabled(true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('rest_timer_notifications_enabled'), isTrue);
      m.dispose();
    });
  });

  group('notification mirroring while enabled', () {
    test('start shows an immediate running notification', () async {
      final fake = FakeRestTimerNotifier();
      final m = await _manager(fake);
      m.start(const Duration(seconds: 90));
      expect(fake.running, isNotEmpty);
      expect(fake.running.last.paused, isFalse);
      expect(fake.running.last.remaining.inSeconds, inInclusiveRange(88, 90));
      m.dispose();
    });

    test('+15 updates the notification immediately (no 15s wait)', () async {
      final fake = FakeRestTimerNotifier();
      final m = await _manager(fake);
      m.start(const Duration(seconds: 60));
      fake.running.clear();
      m.addSeconds(15);
      expect(fake.running, isNotEmpty);
      expect(fake.running.last.remaining.inSeconds, inInclusiveRange(73, 75));
      m.dispose();
    });

    test('pause shows a paused notification and stops the refresh loop',
        () async {
      final fake = FakeRestTimerNotifier();
      final m = await _manager(fake);
      m.start(const Duration(seconds: 90));
      fake.running.clear();
      m.pause();
      expect(fake.running.last.paused, isTrue);
      final frozen = fake.running.last.remaining;
      expect(frozen.inSeconds, inInclusiveRange(88, 90));
      m.dispose();
    });

    test('resume shows a running notification again', () async {
      final fake = FakeRestTimerNotifier();
      final m = await _manager(fake);
      m.start(const Duration(seconds: 90));
      m.pause();
      fake.running.clear();
      m.resume();
      expect(fake.running.last.paused, isFalse);
      m.dispose();
    });

    test('skip cancels the notification and shows no completion', () async {
      final fake = FakeRestTimerNotifier();
      final m = await _manager(fake);
      m.start(const Duration(seconds: 60));
      final cancelsBefore = fake.cancelCount;
      m.skip();
      expect(fake.cancelCount, greaterThan(cancelsBefore));
      expect(fake.completeCount, 0);
      m.dispose();
    });

    test('completion shows the complete notification once', () async {
      final fake = FakeRestTimerNotifier();
      final m = await _manager(fake);
      m.start(const Duration(seconds: 10));
      m.subtractSeconds(30); // drive past zero → completes
      expect(m.isFinished, isTrue);
      expect(fake.completeCount, 1);
      m.dispose();
    });

    test('starting a new timer replaces the old notification state', () async {
      final fake = FakeRestTimerNotifier();
      final m = await _manager(fake);
      m.start(const Duration(seconds: 120));
      m.start(const Duration(seconds: 30));
      // Latest mirror reflects the NEW timer, never the stale 120s one.
      expect(fake.running.last.remaining.inSeconds, inInclusiveRange(28, 30));
      m.dispose();
    });
  });

  group('notification suppression while disabled', () {
    test('start creates no notification when disabled', () async {
      final fake = FakeRestTimerNotifier();
      final m = await _manager(fake);
      await m.setNotificationsEnabled(false);
      fake.running.clear();
      m.start(const Duration(seconds: 60));
      expect(fake.running, isEmpty);
      m.dispose();
    });

    test('completion creates no notification when disabled', () async {
      final fake = FakeRestTimerNotifier();
      final m = await _manager(fake);
      await m.setNotificationsEnabled(false);
      m.start(const Duration(seconds: 10));
      m.subtractSeconds(30);
      expect(m.isFinished, isTrue);
      expect(fake.completeCount, 0);
      m.dispose();
    });
  });

  group('toggling does not affect the timer', () {
    test('turning OFF mid-rest cancels the notification but keeps the timer',
        () async {
      final fake = FakeRestTimerNotifier();
      final m = await _manager(fake);
      m.start(const Duration(seconds: 90));
      final before = m.remaining;

      await m.setNotificationsEnabled(false);

      expect(fake.enabled, isFalse);
      expect(fake.cancelCount, greaterThan(0));
      // Timer itself is untouched.
      expect(m.isRunning, isTrue);
      expect(m.isFinished, isFalse);
      expect(
        (before - m.remaining).inSeconds.abs(),
        lessThanOrEqualTo(1),
      );
      m.dispose();
    });

    test('turning ON mid-rest mirrors the current remaining, no restart',
        () async {
      final fake = FakeRestTimerNotifier();
      final m = await _manager(fake);
      await m.setNotificationsEnabled(false);
      m.start(const Duration(seconds: 90));
      final total = m.total;
      fake.running.clear();

      await m.setNotificationsEnabled(true);

      expect(fake.running, isNotEmpty);
      expect(fake.running.last.paused, isFalse);
      expect(fake.running.last.remaining.inSeconds, inInclusiveRange(87, 90));
      // Not restarted: total is unchanged and it's still the same run.
      expect(m.total, total);
      expect(m.isRunning, isTrue);
      m.dispose();
    });

    test('turning ON while paused mirrors the paused remaining', () async {
      final fake = FakeRestTimerNotifier();
      final m = await _manager(fake);
      await m.setNotificationsEnabled(false);
      m.start(const Duration(seconds: 90));
      m.pause();
      fake.running.clear();

      await m.setNotificationsEnabled(true);

      expect(fake.running.last.paused, isTrue);
      expect(m.isPaused, isTrue);
      m.dispose();
    });
  });
}
