import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/widgets/myCustomeButton.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/home/exercises/exerciesesList.dart';
import 'package:workout_tracker/home/exercises/widgets/exerciseTile.dart';
import 'package:workout_tracker/home/session/sessionViewModel.dart';
import 'package:workout_tracker/home/session/widgets/startSessionPage.dart';
import 'package:workout_tracker/home/templates/models/workoutTemplateModel.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';

class ViewTemplatePage extends StatelessWidget {
  final WorkoutTemplateModel template;

  const ViewTemplatePage({super.key, required this.template});

  @override
  Widget build(BuildContext context) {
    return MyCustomeScaffoldView(
      title: template.name,
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Template icon
          Center(child: Image.asset(template.iconPath, width: 80, height: 80)),
          const SizedBox(height: 12),

          // Template name
          Text(
            template.name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            '${template.exerciseIds.length} exercises',
            style: const TextStyle(color: Colors.black54),
          ),

          const SizedBox(height: 16),
          const Divider(),

          Expanded(
            child: Builder(
              builder: (context) {
                final all = ExercisesViewModel.all;

                final mapById = {for (final e in all) e.id: e};
                final resolved = <ExerciseModel>[
                  for (final id in template.exerciseIds)
                    if (mapById[id] != null) mapById[id]!,
                ];

                if (resolved.isEmpty) {
                  return const Center(
                    child: Text('Exercises not found for this template'),
                  );
                }

                return Column(
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
                      padding: const EdgeInsets.all(8.0),
                      child: MyCustomButton(
                        label: 'Start Session',
                        fullWidth: true,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider(
                                create: (_) => WorkoutSessionViewModel(
                                  templateIcon: template.iconPath,
                                  templateId: template.id,
                                  templateName: template.name,
                                  exerciseIds: resolved
                                      .map((e) => e.id)
                                      .toList(),
                                )..start(),
                                child: StartSessionPage(
                                  templateId: template.id,
                                  templateName: template.name,
                                  exercises: resolved,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
