import 'package:flutter/material.dart';
import 'package:workout_tracker/home/templates/models/workoutTemplateModel.dart';

class TemplatesViewModel extends ChangeNotifier {
  final List<WorkoutTemplateModel> _templates = [];

  List<WorkoutTemplateModel> get templates => List.unmodifiable(_templates);

  void addTemplate(WorkoutTemplateModel template) {
    _templates.add(template);
    notifyListeners();
  }

  void removeTemplate(WorkoutTemplateModel template) {
    _templates.remove(template);
    notifyListeners();
  }

  void updateTemplate(int index, WorkoutTemplateModel template) {
    _templates[index] = template;
    notifyListeners();
  }

  void clearTemplates() {
    _templates.clear();
    notifyListeners();
  }
}
