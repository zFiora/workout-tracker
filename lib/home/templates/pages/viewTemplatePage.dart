import 'package:flutter/material.dart';
import 'package:workout_tracker/common/widgets/myCustomeButton.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/home/exercises/exerciesesList.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/exercises/widgets/exerciseTile.dart';
import 'package:workout_tracker/home/templates/models/workoutTemplateModel.dart';
import 'package:workout_tracker/home/templates/navigation/startSessionFlow.dart';

class ViewTemplatePage extends StatelessWidget {
  final WorkoutTemplateModel template;

  const ViewTemplatePage({super.key, required this.template});

  List<ExerciseModel> _resolveExercises() {
    final all = ExercisesViewModel.all;
    final mapById = {for (final e in all) e.id: e};

    return [
      for (final id in template.exerciseIds)
        if (mapById[id] != null) mapById[id]!,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final resolved = _resolveExercises();

    return MyCustomeScaffoldView(
      title: template.name,
      body: Column(
        children: [
          const SizedBox(height: 16),

          Center(
            child: Image.asset(
              template.iconPath,
              width: 80,
              height: 80,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.fitness_center, size: 64, color: cs.primary),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            template.name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            '${template.exerciseIds.length} exercises',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),

          const SizedBox(height: 16),
          const Divider(),

          Expanded(
            child: resolved.isEmpty
                ? const Center(
                    child: Text('Exercises not found for this template'),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: resolved.length,
                          itemBuilder: (context, index) {
                            final ex = resolved[index];
                            return ExerciseTile(
                              exercise: ex,
                              isSelected: false,
                              onTap: () {},
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: MyCustomButton(
                          label: 'Start Session',
                          fullWidth: true,
                          onPressed: () {
                            StartSessionFlow.push(
                              context: context,
                              templateId: template.id,
                              templateName: template.name,
                              templateIcon: template.iconPath,
                              exercises: resolved,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
