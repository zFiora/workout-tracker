import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/home/exercises/exerciesesList.dart';
import 'package:workout_tracker/home/exercises/widgets/exerciseTile.dart';
import 'package:workout_tracker/home/templates/models/workoutTemplateModel.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';


class ViewTemplatePage extends StatelessWidget {
  final WorkoutTemplateModel template;

  const ViewTemplatePage({super.key, required this.template});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(template.name)),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Template icon
          Center(
            child: Image.asset(
              template.iconPath,
              width: 80,
              height: 80,
            ),
          ),
          const SizedBox(height: 12),

          // Template name
          Text(
            template.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),

          const SizedBox(height: 8),

          // Count from IDs (not objects)
          Text(
            '${template.exerciseIds.length} exercises',
            style: const TextStyle(color: Colors.black54),
          ),

          const SizedBox(height: 16),
          const Divider(),

          // Exercises list resolved from IDs via Consumer
          Expanded(
            child: Consumer<ExercisesViewModel>(
              builder: (context, exVm, _) {
                // master list
                final List<ExerciseModel> all = exVm.exercises;

                // map for quick id -> model
                final mapById = {
                  for (final e in all) e.id: e,
                };

                // resolve ids to models (skip missing)
                final resolved = <ExerciseModel>[
                  for (final id in template.exerciseIds)
                    if (mapById[id] != null) mapById[id]!,
                ];

                if (resolved.isEmpty) {
                  return const Center(
                    child: Text('Exercises not found for this template'),
                  );
                }

                return ListView.builder(
                  itemCount: resolved.length,
                  itemBuilder: (context, index) {
                    final ex = resolved[index];
                    return ExerciseTile(
                      exercise: ex,
                      isSelected: false, // read-only here
                      onTap: () {}, // no-op for now
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
