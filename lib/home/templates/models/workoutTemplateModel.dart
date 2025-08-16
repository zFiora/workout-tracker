import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';

enum WorkoutCategory { legs, back, chest, shoulders, arms, abs }

// New TemplateModel
class WorkoutTemplateModel {
  final String name;
  final String iconPath;
  final List<ExerciseModel> exercises;
  WorkoutTemplateModel({
    required this.name,
    required this.iconPath,
    required this.exercises,
  });
}
