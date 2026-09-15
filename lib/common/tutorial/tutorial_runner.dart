import 'package:flutter/widgets.dart';

import 'coach_mark.dart';
import 'coach_mark_overlay.dart';
import 'tutorial_store.dart';

export 'coach_mark.dart';
export 'coach_mark_overlay.dart';
export 'tutorial_store.dart';

/// Central registry of the app's tutorials and their current versions.
///
/// Each id maps to a `tutorial_<id>_version` key in [TutorialStore]. Bump a
/// version here (and add/adjust that page's steps) to re-show *only* that
/// tutorial after shipping a new feature — every other tutorial is untouched.
class Tutorials {
  const Tutorials._();

  static const String templates = 'templates';
  static const String workout = 'workout';
  static const String exercises = 'exercises';
  static const String exerciseDetails = 'exercise_details';
  static const String history = 'history';
  static const String social = 'social';

  static const Map<String, int> versions = {
    templates: 1,
    workout: 1,
    exercises: 1,
    exerciseDetails: 1,
    history: 1,
    social: 1,
  };

  static int versionOf(String id) => versions[id] ?? 1;
}

/// Wires a page to its tutorial with a single call from `initState`.
///
/// Usage from a `State`:
/// ```dart
/// TutorialRunner.schedule(
///   context,
///   id: Tutorials.workout,
///   steps: () => [ CoachMarkStep(targetKey: _addKey, title: ..., description: ...) ],
/// );
/// ```
///
/// It waits for the first frame (plus a short settle delay so pushed-route
/// transitions and post-frame layout finish), checks the store, runs the
/// overlay, and records the tutorial as seen only if a step was actually shown.
class TutorialRunner {
  const TutorialRunner._();

  static Future<void> schedule(
    BuildContext context, {
    required String id,
    required List<CoachMarkStep> Function() steps,
    int? version,
    TutorialStore store = const TutorialStore(),
    Duration settle = const Duration(milliseconds: 400),
  }) async {
    final v = version ?? Tutorials.versionOf(id);

    // Bail early (before any delay) if this tutorial has already been seen.
    if (!await store.shouldShow(id, v)) return;
    if (!context.mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      await Future<void>.delayed(settle);
      if (!context.mounted) return;

      final shown = await runCoachMarks(context, steps());
      if (shown) await store.markSeen(id, v);
    });
  }
}
