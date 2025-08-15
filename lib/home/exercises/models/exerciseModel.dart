// ignore_for_file: file_names

import 'package:workout_tracker/home/exercises/models/categoryModel.dart';

class ExerciseModel {
  final String name;
  final WorkoutCategory category;
  final String workoutImage;
  ExerciseModel({
    required this.name,
    required this.category,
    required this.workoutImage,
  });
}
