// pages/start_session_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/history/historyViewModel.dart';
import 'package:workout_tracker/home/history/widgets/historyPage.dart';
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

  Future<bool> _confirmEndSession(BuildContext context) async {
    return (await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('End session?'),
            content: const Text('This will save your workout to history.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('End & Save'),
              ),
            ],
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<WorkoutSessionViewModel>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          templateName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined, size: 16, color: cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      _format(session.elapsed),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      body: exercises.isEmpty
          ? _EmptyExercisesState(
              templateName: templateName,
              isRunning: session.isRunning,
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 110),
              itemCount: exercises.length,
              itemBuilder: (context, i) {
                final ex = exercises[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ExerciseSessionTile(
                    exercise: ex,
                    templateId: templateId,
                  ),
                );
              },
            ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(color: cs.outlineVariant.withOpacity(0.6)),
            ),
          ),
          child: Row(
            children: [
              // Secondary action (optional but makes UI feel complete)
              IconButton(
                tooltip: 'History',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryPage()),
                  );
                },
                icon: const Icon(Icons.history),
              ),
              const SizedBox(width: 8),

              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: session.isRunning ? Colors.red : null,
                    ),
                    onPressed: () async {
                      if (!session.isRunning) {
                        session.start();
                        return;
                      }

                      // confirm before ending
                      final ok = await _confirmEndSession(context);
                      if (!ok) return;

                      final entry = session.end();
                      await context.read<HistoryViewModel>().save(entry);

                      if (!context.mounted) return;

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HistoryPage()),
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Workout saved to history')),
                      );
                    },
                    child: Text(session.isRunning ? 'End & Save' : 'Start Session'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyExercisesState extends StatelessWidget {
  final String templateName;
  final bool isRunning;

  const _EmptyExercisesState({
    required this.templateName,
    required this.isRunning,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.playlist_add, size: 44, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'No exercises in this template',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add exercises to "$templateName" to start a session.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            if (isRunning)
              Text(
                'Note: you currently have an active session running.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}
