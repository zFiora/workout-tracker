// Tests for the combined template-edit path (name + icon + exercise
// list/order in one write) used by the redesigned EditTemplatePage.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:workout_tracker/home/templates/models/workout_template.dart';
import 'package:workout_tracker/home/templates/repositories/hiveTemplatesRepositories.dart';

void main() {
  late Directory tempDir;
  late HiveTemplatesRepository repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('templates_edit_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(101)) {
      Hive.registerAdapter(WorkoutTemplateModelAdapter());
    }
    await Hive.openBox<WorkoutTemplateModel>('templatesBox');
    repo = HiveTemplatesRepository();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  WorkoutTemplateModel makeTemplate() {
    final now = DateTime.now();
    return WorkoutTemplateModel(
      id: 't1',
      name: 'Push Day',
      iconPath: 'chest.png',
      exerciseIds: const [3, 2, 4],
      createdAt: now,
      updatedAt: now,
    );
  }

  test('update() applies only the fields passed, leaving others untouched', () async {
    final template = makeTemplate();
    await repo.add(template);

    await repo.update(template, exerciseIds: [3, 2, 4, 5]);

    final updated = repo.byId('t1')!;
    expect(updated.exerciseIds, [3, 2, 4, 5]);
    expect(updated.name, 'Push Day'); // unchanged
    expect(updated.iconPath, 'chest.png'); // unchanged
  });

  test('update() can change name, icon, and exercises together', () async {
    final template = makeTemplate();
    await repo.add(template);

    await repo.update(
      template,
      name: 'Push Day (Modified)',
      iconPath: 'shoulders.png',
      exerciseIds: [2, 3],
    );

    final updated = repo.byId('t1')!;
    expect(updated.name, 'Push Day (Modified)');
    expect(updated.iconPath, 'shoulders.png');
    expect(updated.exerciseIds, [2, 3]);
    // Same-millisecond test runs can tie with the original updatedAt — the
    // one thing that must never happen is going backwards.
    expect(updated.updatedAt.isBefore(template.updatedAt), isFalse);
  });

  test('update() reorders without changing membership', () async {
    final template = makeTemplate();
    await repo.add(template);

    await repo.update(template, exerciseIds: [4, 3, 2]);

    final updated = repo.byId('t1')!;
    expect(updated.exerciseIds, [4, 3, 2]);
    expect(updated.exerciseIds.toSet(), template.exerciseIds.toSet());
  });

  test("update() on an id that doesn't exist is a safe no-op", () async {
    final ghost = makeTemplate().copyWith(); // never added to the box
    await repo.update(ghost, name: 'New name');
    expect(repo.byId('t1'), isNull);
  });
}
