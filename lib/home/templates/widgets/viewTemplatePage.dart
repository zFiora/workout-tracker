import 'package:flutter/material.dart';
import 'package:workout_tracker/home/exercises/widgets/exerciseTile.dart';
import 'package:workout_tracker/home/templates/models/workoutTemplateModel.dart';

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
          Text(
            '${template.exercises.length} exercises',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          const Divider(),
          // Exercises list
          Expanded(
            child: ListView.builder(
              itemCount: template.exercises.length,
              itemBuilder: (context, index) {
                final ex = template.exercises[index];
                return ExerciseTile(
                  exercise: ex,
                  isSelected: false, // read-only
                  onTap: () {}, // do nothing on tap
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
