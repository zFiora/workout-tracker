import 'package:flutter/foundation.dart';
import 'package:workout_tracker/home/templates/models/workoutTemplateModel.dart';
import 'package:workout_tracker/home/templates/repositories/hiveTemplatesRepositories.dart';
import 'package:workout_tracker/home/templates/repositories/templatesRepositories.dart';

class TemplatesViewModel extends ChangeNotifier {
  TemplatesViewModel({TemplatesRepository? repo})
    : _repo = repo ?? HiveTemplatesRepository();

  final TemplatesRepository _repo;

  List<WorkoutTemplateModel> get templates => _repo.getAllSorted();

  WorkoutTemplateModel? byId(String id) => _repo.byId(id);

  Future<void> addTemplate(WorkoutTemplateModel template) async {
    await _repo.add(template);
    notifyListeners();
  }

  Future<void> deleteTemplate(WorkoutTemplateModel template) async {
    await _repo.delete(template);
    notifyListeners();
  }

  Future<void> renameTemplate(
    WorkoutTemplateModel template,
    String newName,
  ) async {
    await _repo.rename(template, newName);
    notifyListeners();
  }

  Future<void> changeIconPath(
    WorkoutTemplateModel template,
    String newIconPath,
  ) async {
    await _repo.changeIconPath(template, newIconPath);
    notifyListeners();
  }
}
