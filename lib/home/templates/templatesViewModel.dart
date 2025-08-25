import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:workout_tracker/home/templates/models/workoutTemplateModel.dart';

class TemplatesViewModel extends ChangeNotifier {
  late final Box<WorkoutTemplateModel> _box;

  TemplatesViewModel() {
    _box = Hive.box<WorkoutTemplateModel>('templatesBox');
  }

  List<WorkoutTemplateModel> get templates =>
      _box.values.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  Future<void> addTemplate(WorkoutTemplateModel template) async {
    await _box.add(template);
    notifyListeners();
  }

  Future<void> deleteTemplate(WorkoutTemplateModel template) async {
    await template.delete();
    notifyListeners();
  }

  Future<void> renameTemplate(
    WorkoutTemplateModel template,
    String newName,
  ) async {
    template
      ..name = newName
      ..updatedAt = DateTime.now();
    await template.save();
    notifyListeners();
  }

  WorkoutTemplateModel? byId(String id) {
    try {
      return _box.values.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> changeIconPath(
    WorkoutTemplateModel template,
    String newIconPath,
  ) async {
    template
      ..iconPath = newIconPath
      ..updatedAt = DateTime.now();
    await template.save();
    notifyListeners();
  }
}
