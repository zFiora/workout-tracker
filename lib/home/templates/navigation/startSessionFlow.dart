import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/session/active_session_manager.dart';
import 'package:workout_tracker/home/session/pages/startSessionPage.dart';

class StartSessionFlow {
  static void push({
    required BuildContext context,
    required String templateId,
    required String templateName,
    required String templateIcon,
    required List<ExerciseModel> exercises,
  }) {
    context.read<ActiveSessionManager>().startSession(
      templateId: templateId,
      templateName: templateName,
      templateIcon: templateIcon,
      exercises: exercises,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StartSessionPage()),
    );
  }
}
