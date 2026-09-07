// Tests for the mid-session exercise editing + template-change detection
// added for "Workout Templates & Mid-Session Exercise Management".

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:workout_tracker/home/exercises/exerciesesList.dart';
import 'package:workout_tracker/home/session/active_session_manager.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'active_session_manager_test',
    );
    Hive.init(tempDir.path);
    await Hive.openBox('activeSessionBox');
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  final all = ExercisesViewModel.all;
  final benchPress = all.firstWhere((e) => e.id == 3); // Bench Press (Barbell)
  final inclinePress = all.firstWhere((e) => e.id == 2);
  final flatSmith = all.firstWhere((e) => e.id == 4);
  final cableFly = all.firstWhere((e) => e.id == 5);

  ActiveSessionManager start(List<int> ids) {
    final manager = ActiveSessionManager();
    manager.startSession(
      templateId: 'push-day',
      templateName: 'Push Day',
      templateIcon: 'icon.png',
      exercises: [benchPress, inclinePress, flatSmith]
          .where((e) => ids.contains(e.id))
          .toList(),
    );
    return manager;
  }

  group('exercisesWereModified', () {
    test('false with no changes', () {
      final manager = start([3, 2, 4]);
      expect(manager.exercisesWereModified, isFalse);
    });

    test('true after adding an exercise', () {
      final manager = start([3, 2, 4]);
      manager.addExerciseToSession(cableFly);
      expect(manager.exercisesWereModified, isTrue);
    });

    test('true after removing an exercise', () {
      final manager = start([3, 2, 4]);
      manager.removeExerciseFromSession(inclinePress);
      expect(manager.exercisesWereModified, isTrue);
    });

    test('false after adding then removing the same exercise', () {
      final manager = start([3, 2, 4]);
      manager.addExerciseToSession(cableFly);
      manager.removeExerciseFromSession(cableFly);
      expect(manager.exercisesWereModified, isFalse);
    });

    test('true after a pure reorder (no add/remove)', () {
      final manager = start([3, 2, 4]);
      // swap positions 0 and 1
      manager.reorderExercise(0, 2);
      expect(
        manager.exercises.map((e) => e.id).toList(),
        [2, 3, 4],
      );
      expect(manager.exercisesWereModified, isTrue);
    });

    test('false when a reorder ends up back at the original order', () {
      final manager = start([3, 2, 4]);
      manager.reorderExercise(0, 2); // [2, 3, 4]
      manager.reorderExercise(1, 0); // back to [3, 2, 4]
      expect(manager.exercises.map((e) => e.id).toList(), [3, 2, 4]);
      expect(manager.exercisesWereModified, isFalse);
    });
  });

  group('reorderExercise', () {
    test('moves an item forward', () {
      final manager = start([3, 2, 4]);
      manager.reorderExercise(0, 2); // move Bench Press to index 1
      expect(manager.exercises.map((e) => e.id).toList(), [2, 3, 4]);
    });

    test('moves an item backward', () {
      final manager = start([3, 2, 4]);
      manager.reorderExercise(2, 0); // move Flat Smith Press to the front
      expect(manager.exercises.map((e) => e.id).toList(), [4, 3, 2]);
    });

    test('is a no-op for an out-of-range index', () {
      final manager = start([3, 2, 4]);
      manager.reorderExercise(0, 99);
      expect(manager.exercises.map((e) => e.id).toList(), [3, 2, 4]);
    });
  });

  test('endSession clears the active session but the manager stays usable', () {
    final manager = start([3, 2, 4]);
    final entry = manager.endSession();
    expect(entry.templateId, 'push-day');
    expect(manager.hasActiveSession, isFalse);
  });
}
