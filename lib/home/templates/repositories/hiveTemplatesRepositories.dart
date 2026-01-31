import 'package:hive/hive.dart';
import 'package:workout_tracker/home/templates/models/workoutTemplateModel.dart';
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
    try {
      return _box.values.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> add(WorkoutTemplateModel template) async {
    await _box.add(template);
  }

  @override
  Future<void> delete(WorkoutTemplateModel template) async {
    await template.delete();
  }

  @override
  Future<void> rename(WorkoutTemplateModel template, String newName) async {
    template
      ..name = newName
      ..updatedAt = DateTime.now();
    await template.save();
  }

  @override
  Future<void> changeIconPath(
    WorkoutTemplateModel template,
    String newIconPath,
  ) async {
    template
      ..iconPath = newIconPath
      ..updatedAt = DateTime.now();
    await template.save();
  }
}
