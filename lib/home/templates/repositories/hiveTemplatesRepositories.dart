import 'package:hive/hive.dart';
import 'package:workout_tracker/home/templates/models/workout_template.dart';
import 'package:workout_tracker/home/templates/repositories/templatesRepositories.dart';

class HiveTemplatesRepository implements TemplatesRepository {
  HiveTemplatesRepository({Box<WorkoutTemplateModel>? box})
    : _box = box ?? Hive.box<WorkoutTemplateModel>('templatesBox');

  final Box<WorkoutTemplateModel> _box;

  @override
  List<WorkoutTemplateModel> getAllSorted() {
    final list = _box.values.toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  @override
  WorkoutTemplateModel? byId(String id) {
    for (final t in _box.values) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Helper: find Hive key for a template id (since model is not HiveObject anymore)
  dynamic _keyOfId(String id) {
    for (final key in _box.keys) {
      final t = _box.get(key);
      if (t != null && t.id == id) return key;
    }
    return null;
  }

  @override
  Future<void> add(WorkoutTemplateModel template) async {
    await _box.add(template);
  }

  @override
  Future<void> delete(WorkoutTemplateModel template) async {
    final key = _keyOfId(template.id);
    if (key == null) return;
    await _box.delete(key);
  }

  @override
  Future<void> rename(WorkoutTemplateModel template, String newName) async {
    final key = _keyOfId(template.id);
    if (key == null) return;

    final updated = template.copyWith(name: newName, updatedAt: DateTime.now());
    await _box.put(key, updated);
  }

  @override
  Future<void> changeIconPath(
    WorkoutTemplateModel template,
    String newIconPath,
  ) async {
    final key = _keyOfId(template.id);
    if (key == null) return;

    final updated = template.copyWith(
      iconPath: newIconPath,
      updatedAt: DateTime.now(),
    );
    await _box.put(key, updated);
  }

  @override
  Future<void> updateExercises(
    WorkoutTemplateModel template,
    List<int> newExerciseIds,
  ) async {
    final key = _keyOfId(template.id);
    if (key == null) return;

    final updated = template.copyWith(
      exerciseIds: newExerciseIds,
      updatedAt: DateTime.now(),
    );
    await _box.put(key, updated);
  }
}
