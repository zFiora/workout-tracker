import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/home/account/model/profileStats.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

PerformedSet _set(double w, int r, {SetType type = SetType.work}) => PerformedSet(
      weight: w,
      reps: r,
      timestamp: DateTime(2026, 1, 1),
      type: type,
    );

WorkoutHistoryEntry _entry({
  required String template,
  required Duration duration,
  required List<ExerciseLog> logs,
}) {
  final start = DateTime(2026, 1, 1, 9);
  return WorkoutHistoryEntry(
    id: template,
    templateId: template,
    templateName: template,
    templateIcon: '',
    startedAt: start,
    endedAt: start.add(duration),
    duration: duration,
    logs: logs,
  );
}

void main() {
  test('empty history yields zeroed stats', () {
    final s = ProfileStats.from(const []);
    expect(s.workouts, 0);
    expect(s.totalTime, Duration.zero);
    expect(s.totalVolumeKg, 0);
    expect(s.exercisesTracked, 0);
  });

  test('aggregates workouts, time, volume and distinct exercises', () {
    final history = [
      _entry(
        template: 'push',
        duration: const Duration(minutes: 45),
        logs: [
          ExerciseLog(
            exerciseId: 1,
            exerciseName: 'Bench',
            exerciseIcon: '',
            sets: [_set(100, 5), _set(100, 5)], // 1000 volume
          ),
          ExerciseLog(
            exerciseId: 2,
            exerciseName: 'Incline',
            exerciseIcon: '',
            sets: [_set(60, 10)], // 600
          ),
        ],
      ),
      _entry(
        template: 'pull',
        duration: const Duration(minutes: 30),
        logs: [
          ExerciseLog(
            exerciseId: 1, // same exercise id as before → still distinct-count 1
            exerciseName: 'Bench',
            exerciseIcon: '',
            sets: [_set(50, 10)], // 500
          ),
        ],
      ),
    ];

    final s = ProfileStats.from(history);
    expect(s.workouts, 2);
    expect(s.totalTime, const Duration(minutes: 75));
    expect(s.totalVolumeKg, 2100);
    expect(s.exercisesTracked, 2); // ids {1, 2}
  });

  test('warmup / non-work sets are excluded from volume', () {
    final history = [
      _entry(
        template: 'legs',
        duration: const Duration(minutes: 20),
        logs: [
          ExerciseLog(
            exerciseId: 5,
            exerciseName: 'Squat',
            exerciseIcon: '',
            sets: [
              _set(40, 10, type: SetType.warmup), // excluded
              _set(100, 5), // 500
            ],
          ),
        ],
      ),
    ];

    expect(ProfileStats.from(history).totalVolumeKg, 500);
  });
}
