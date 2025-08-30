// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/home/exercises/exerciesesList.dart';
import 'package:workout_tracker/home/exercises/widgets/exerciseFilterList.dart';

class ExercisesPage extends StatelessWidget {
  const ExercisesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final exercises = ExercisesViewModel.all;
    return MyCustomeScaffoldView(
      title: 'Exercises',
      body: ExerciseFilterList(exercises: exercises),
    );
  }
}
