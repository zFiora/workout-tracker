import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:workout_tracker/home/templates/models/workout_template.dart';
import 'package:workout_tracker/home/templates/repositories/hiveTemplatesRepositories.dart';
import 'package:workout_tracker/home/templates/repositories/templatesRepositories.dart';

class TemplatesViewModel extends ChangeNotifier {
  TemplatesViewModel({TemplatesRepository? repo})
    : _repo = repo ?? HiveTemplatesRepository() {
    // Auto-refresh UI when the Hive box changes (add/put/delete)
    _sub = Hive.box<WorkoutTemplateModel>(
      'templatesBox',
    ).watch().listen((_) => notifyListeners());
  }

  final TemplatesRepository _repo;
  StreamSubscription<BoxEvent>? _sub;

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

  Future<void> updateExercises(
    WorkoutTemplateModel template,
    List<int> newExerciseIds,
  ) async {
    await _repo.updateExercises(template, newExerciseIds);
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
