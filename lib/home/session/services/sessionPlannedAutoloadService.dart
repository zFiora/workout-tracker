import 'package:workout_tracker/home/history/ViewModel/historyViewModel.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

class SessionPlanAutoloadService {
  List<PerformedSet> lastWorkoutSetsForExercise({
    required HistoryViewModel historyVM,
    required String templateId,
    required int exerciseId,
  }) {
    if (historyVM.history.isEmpty) return const [];

    final templateEntries =
        historyVM.history.where((e) => e.templateId == templateId).toList();
    if (templateEntries.isEmpty) return const [];

    templateEntries.sort((a, b) => b.endedAt.compareTo(a.endedAt));

    for (final entry in templateEntries) {
      final exLog = entry.logs.cast<ExerciseLog?>().firstWhere(
            (l) => l?.exerciseId == exerciseId,
            orElse: () => null,
          );

      final sets = exLog?.sets ?? const <PerformedSet>[];
      if (sets.isNotEmpty) return List<PerformedSet>.from(sets);
    }

    return const [];
  }
}
