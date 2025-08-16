// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/home/exercises/exerciesesList.dart';
import 'package:workout_tracker/home/exercises/widgets/exerciseFilterList.dart';

class ExercisesPage extends StatelessWidget {
  const ExercisesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final exercises = Provider.of<ExercisesViewModel>(context).exercises;
    return MyCustomeScaffoldView(
      title: 'Exercises',
      body: ExerciseFilterList(exercises: exercises),
    );
  }
}
