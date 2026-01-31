import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/session/pages/startSessionPage.dart';
import 'package:workout_tracker/home/session/sessionViewModel.dart';

class StartSessionFlow {
  static void push({
    required BuildContext context,
    required String templateId,
    required String templateName,
    required String templateIcon,
    required List<ExerciseModel> exercises,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => WorkoutSessionViewModel(
            templateIcon: templateIcon,
            templateId: templateId,
            templateName: templateName,
            exerciseIds: exercises.map((e) => e.id).toList(),
          )..start(),
          child: StartSessionPage(
            templateId: templateId,
            templateName: templateName,
            exercises: exercises,
          ),
        ),
      ),
    );
  }
}
