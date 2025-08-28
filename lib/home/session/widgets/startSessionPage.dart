// pages/start_session_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/history_page/historyViewModel.dart';
import 'package:workout_tracker/home/session/sessionViewModel.dart';
import 'package:workout_tracker/home/session/widgets/exerciseSessionTile.dart';

class StartSessionPage extends StatelessWidget {
  final String templateName;
  final String templateId;
  final List<ExerciseModel> exercises;

  const StartSessionPage({
    super.key,
    required this.templateName,
    required this.exercises,
    required this.templateId,
  });

  String _format(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<WorkoutSessionViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(templateName),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                _format(session.elapsed),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: exercises.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final ex = exercises[i];
                return ExerciseSessionTile(
                  exercise: ex,
                  templateId: templateId,
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: session.isRunning
                        ? Colors.red
                        : Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    if (session.isRunning) {
                      final entry = session.end();
                      await context.read<HistoryViewModel>().save(entry);

                      if (context.mounted) {
                        Navigator.pop(context); // back to template view
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Workout saved to history'),
                          ),
                        );
                      }
                    } else {
                      session.start();
                    }
                  },
                  child: Text(
                    session.isRunning ? 'End Session' : 'Start Session',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
