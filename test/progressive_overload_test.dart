import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';
import 'package:workout_tracker/home/session/services/progressive_overload_service.dart';

PerformedSet _s(double w, int r, [SetType type = SetType.work]) =>
    PerformedSet(weight: w, reps: r, timestamp: DateTime(2026), type: type);

void main() {
  const svc = ProgressiveOverloadService(); // +2.5kg, ceiling 8, floor 5

  test('no history → no suggestion', () {
    expect(svc.suggestFrom(const []), isEmpty);
  });

  test('strong sets (reps >= ceiling) add a weight step, keep reps', () {
    final t = svc.suggestFrom([_s(100, 8), _s(100, 8)]);
    expect(t.length, 2);
    expect(t[0].weightKg, 102.5);
    expect(t[0].reps, 8);
  });

  test('mid sets (floor..ceiling-1) keep weight, add a rep', () {
    final t = svc.suggestFrom([_s(100, 6)]);
    expect(t[0].weightKg, 100);
    expect(t[0].reps, 7);
  });

  test('grind sets (< floor) repeat exactly', () {
    final t = svc.suggestFrom([_s(140, 3)]);
    expect(t[0].weightKg, 140);
    expect(t[0].reps, 3);
  });

  test('warm-up and drop sets are ignored', () {
    final t = svc.suggestFrom([
      _s(40, 12, SetType.warmup),
      _s(100, 8),
      _s(80, 10, SetType.dropset),
    ]);
    expect(t.length, 1);
    expect(t[0].weightKg, 102.5);
  });

  test('differsFrom is false when suggestion equals last performance', () {
    // A grind set repeats exactly → no meaningful progression to offer.
    final last = [_s(140, 3)];
    final t = svc.suggestFrom(last);
    expect(svc.differsFrom(t, last), isFalse);
  });

  test('differsFrom is true when a weight/rep changes', () {
    final last = [_s(100, 8)];
    final t = svc.suggestFrom(last);
    expect(svc.differsFrom(t, last), isTrue);
  });
}
