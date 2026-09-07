import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_tracker/home/session/rest_timer_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('idle by default', () {
    final m = RestTimerManager();
    expect(m.isActive, isFalse);
    expect(m.remaining, Duration.zero);
    m.dispose();
  });

  test('start puts it in the running state with ~full remaining', () {
    final m = RestTimerManager();
    m.start(const Duration(seconds: 120));
    expect(m.isRunning, isTrue);
    expect(m.isActive, isTrue);
    // Computed from wall clock; allow a small delta for test execution time.
    expect(m.remaining.inSeconds, inInclusiveRange(118, 120));
    m.dispose();
  });

  test('pause freezes remaining; resume keeps running', () {
    final m = RestTimerManager();
    m.start(const Duration(seconds: 90));
    m.pause();
    expect(m.isPaused, isTrue);
    expect(m.isRunning, isFalse);
    final frozen = m.remaining;
    expect(frozen.inSeconds, inInclusiveRange(88, 90));
    m.resume();
    expect(m.isRunning, isTrue);
    expect(m.isPaused, isFalse);
    m.dispose();
  });

  test('+15 / −15 adjust remaining', () {
    final m = RestTimerManager();
    m.start(const Duration(seconds: 60));
    m.addSeconds(15);
    expect(m.remaining.inSeconds, inInclusiveRange(73, 75));
    m.subtractSeconds(15);
    expect(m.remaining.inSeconds, inInclusiveRange(58, 60));
    m.dispose();
  });

  test('subtracting past zero finishes the timer', () {
    final m = RestTimerManager();
    m.start(const Duration(seconds: 10));
    m.subtractSeconds(30);
    expect(m.isFinished, isTrue);
    expect(m.isRunning, isFalse);
    expect(m.remaining, Duration.zero);
    m.dispose();
  });

  test('skip clears everything', () {
    final m = RestTimerManager();
    m.start(const Duration(seconds: 60));
    m.skip();
    expect(m.isActive, isFalse);
    m.dispose();
  });

  test('default duration persists', () async {
    final m = RestTimerManager();
    await m.setDefaultSeconds(150);
    expect(m.defaultSeconds, 150);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('rest_default_seconds'), 150);
    m.dispose();
  });

  test('starting again replaces the previous countdown (no stacking)', () {
    final m = RestTimerManager();
    m.start(const Duration(seconds: 120));
    m.start(const Duration(seconds: 30));
    expect(m.total, const Duration(seconds: 30));
    expect(m.remaining.inSeconds, inInclusiveRange(28, 30));
    m.dispose();
  });
}
