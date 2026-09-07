import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/session/active_session_manager.dart';
import 'package:workout_tracker/home/session/pages/startSessionPage.dart';

enum _ActiveSessionChoice { goToActive, discardAndStartNew }

/// Central entry point for starting a session from a template — every call
/// site funnels through here, so the "there's already a session running"
/// guard only has to exist once.
class StartSessionFlow {
  /// [ActiveSessionManager.startSession] unconditionally tears down whatever
  /// session is currently running with no save and no warning. Without this
  /// guard, tapping "Start Session" on template B while template A's workout
  /// is still in progress would silently destroy every set logged in A.
  static Future<void> push({
    required BuildContext context,
    required String templateId,
    required String templateName,
    required String templateIcon,
    required List<ExerciseModel> exercises,
  }) async {
    final manager = context.read<ActiveSessionManager>();

    if (manager.hasActiveSession) {
      final activeName = manager.templateName ?? 'your active workout';
      final choice = await showDialog<_ActiveSessionChoice>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Workout in progress'),
          content: Text(
            'You have an active workout ("$activeName"). Starting "$templateName" '
            'now will discard it — any sets you\'ve logged will be lost.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(ctx, _ActiveSessionChoice.goToActive),
              child: const Text('Go to active workout'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(ctx).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(
                ctx,
                _ActiveSessionChoice.discardAndStartNew,
              ),
              child: const Text('Discard & start new'),
            ),
          ],
        ),
      );

      if (choice == null || !context.mounted) return; // cancelled

      if (choice == _ActiveSessionChoice.goToActive) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StartSessionPage()),
        );
        return;
      }
      // else: discardAndStartNew falls through to start fresh below.
    }

    manager.startSession(
      templateId: templateId,
      templateName: templateName,
      templateIcon: templateIcon,
      exercises: exercises,
    );

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StartSessionPage()),
    );
  }
}
