// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:workout_tracker/common/widgets/myCustomSearchField.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/home/exercises/exerciesesList.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/exercises/widgets/exerciseFilterList.dart';
import 'package:workout_tracker/home/social/pages/exercise_leaderboard_page.dart';

class ExercisesPage extends StatefulWidget {
  const ExercisesPage({super.key});

  @override
  State<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  String _query = '';

  void _openLeaderboard(ExerciseModel exercise) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseLeaderboardPage(exercise: exercise),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = ExercisesViewModel.all;
    final filtered = _query.trim().isEmpty
        ? all
        : all
            .where(
              (e) => e.name.toLowerCase().contains(_query.trim().toLowerCase()),
            )
            .toList();

    return MyCustomeScaffoldView(
      title: 'Exercises',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: MyCustomSearchField(
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ExerciseFilterList(
              exercises: filtered,
              onExerciseOpen: _openLeaderboard,
            ),
          ),
        ],
      ),
    );
  }
}
