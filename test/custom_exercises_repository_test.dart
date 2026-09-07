import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:workout_tracker/home/exercises/custom_exercises_repository.dart';
import 'package:workout_tracker/home/exercises/models/categoryModel.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';

void main() {
  late Directory dir;

  ExerciseModel draft(String name, WorkoutCategory cat) => ExerciseModel(
        id: 0,
        name: name,
        category: cat,
        workoutImage: '',
        equipment: 'Barbell',
        isCustom: true,
      );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('custom_ex_test');
    Hive.init(dir.path);
    await Hive.openBox<String>(CustomExercisesRepository.boxName);
    CustomExercisesRepository.I.load();
    // Ensure a clean box between tests.
    await Hive.box<String>(CustomExercisesRepository.boxName).clear();
    CustomExercisesRepository.I.load();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  test('created custom exercises get reserved ids (>= 1,000,000)', () async {
    final a = await CustomExercisesRepository.I.create(draft('Zercher Squat', WorkoutCategory.legs));
    final b = await CustomExercisesRepository.I.create(draft('Meadows Row', WorkoutCategory.back));
    expect(CustomExercisesRepository.isCustomId(a.id), isTrue);
    expect(CustomExercisesRepository.isCustomId(b.id), isTrue);
    expect(a.id, greaterThanOrEqualTo(1000000));
    expect(b.id, greaterThan(a.id)); // unique, monotonic
    expect(a.isCustom, isTrue);
  });

  test('custom ids never collide with built-in range', () {
    expect(CustomExercisesRepository.isCustomId(1), isFalse);
    expect(CustomExercisesRepository.isCustomId(64), isFalse);
    expect(CustomExercisesRepository.isCustomId(999999), isFalse);
    expect(CustomExercisesRepository.isCustomId(1000000), isTrue);
  });

  test('persists across a reload (simulated app restart)', () async {
    final a =
        await CustomExercisesRepository.I.create(draft('Pendlay Row', WorkoutCategory.back));

    // Simulate restart: reload the cache from the box.
    CustomExercisesRepository.I.load();

    final found = CustomExercisesRepository.I.byId(a.id);
    expect(found, isNotNull);
    expect(found!.name, 'Pendlay Row');
    expect(found.equipment, 'Barbell');
  });

  test('update changes fields but keeps the id', () async {
    final a = await CustomExercisesRepository.I.create(draft('Row', WorkoutCategory.back));
    await CustomExercisesRepository.I.update(a.copyWith(name: 'Barbell Row'));
    final found = CustomExercisesRepository.I.byId(a.id);
    expect(found!.name, 'Barbell Row');
    expect(found.id, a.id);
  });

  test('delete removes only that custom exercise', () async {
    final a = await CustomExercisesRepository.I.create(draft('A', WorkoutCategory.chest));
    final b = await CustomExercisesRepository.I.create(draft('B', WorkoutCategory.chest));
    await CustomExercisesRepository.I.delete(a.id);
    expect(CustomExercisesRepository.I.byId(a.id), isNull);
    expect(CustomExercisesRepository.I.byId(b.id), isNotNull);
  });

  test('update/delete ignore built-in ids (never corrupts the catalog)', () async {
    // A built-in id (< reserved base) must be a no-op.
    await CustomExercisesRepository.I.update(
      ExerciseModel(id: 3, name: 'hack', category: WorkoutCategory.chest, workoutImage: ''),
    );
    await CustomExercisesRepository.I.delete(3);
    expect(CustomExercisesRepository.I.all, isEmpty);
  });
}
