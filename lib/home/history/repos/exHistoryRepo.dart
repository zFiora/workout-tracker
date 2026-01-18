import 'package:hive/hive.dart';
import 'package:workout_tracker/home/history/models/PRModels.dart';
import 'package:workout_tracker/home/history/utils/strengthUtils.dart';

import '../../session/models/sessionModels.dart';

enum ChartMetric { bestWeight, bestEstimated1RM }

class ExerciseSessionSummary {
  final DateTime day; // normalized day (YYYY-MM-DD)
  final DateTime endedAt;
  final List<PerformedSet> sets;

  final double sessionVolume;
  final double bestWeight;
  final int bestReps;
  final double bestEstimated1RM;

  ExerciseSessionSummary({
    required this.day,
    required this.endedAt,
    required this.sets,
    required this.sessionVolume,
    required this.bestWeight,
    required this.bestReps,
    required this.bestEstimated1RM,
  });
}

class ExerciseHistoryRepository {
  ExerciseHistoryRepository(this.box);

  final Box<WorkoutHistoryEntry> box;

  // Your ExerciseLog stores exerciseId as int. No "exercise" property exists.
  int? _logExerciseId(dynamic log) {
    final id = (log as dynamic).exerciseId;
    if (id is int) return id;
    return null;
  }

  List<ExerciseSessionSummary> sessionsForExercise(int exerciseId) {
    final byDay = <DateTime, _Agg>{};

    for (final key in box.keys) {
      final entry = box.get(key);
      if (entry == null) continue;

      final endedAt = entry.endedAt;
      final day = DateTime(endedAt.year, endedAt.month, endedAt.day);

      for (final log in entry.logs) {
        final int? id = _logExerciseId(log);
        if (id == null || id != exerciseId) continue;

        final sets = (log as dynamic).sets as List<dynamic>;
        final agg = byDay.putIfAbsent(
          day,
          () => _Agg(day: day, endedAt: endedAt),
        );

        for (final s in sets) {
          if (s is! PerformedSet) continue;

          agg.sets.add(s);

          agg.volume += (s.weight * s.reps);
          if (s.weight > agg.bestW) agg.bestW = s.weight;
          if (s.reps > agg.bestR) agg.bestR = s.reps;

          final est = estimate1RM(weight: s.weight, reps: s.reps);
          if (est > agg.best1rm) agg.best1rm = est;
        }

        if (endedAt.isAfter(agg.endedAt)) agg.endedAt = endedAt;
      }
    }

    final list = byDay.values.map((a) => a.toSummary()).toList()
      ..sort((a, b) => b.endedAt.compareTo(a.endedAt));

    return list;
  }

  List<ExerciseSessionSummary> lastSessions(int exerciseId, {int limit = 5}) =>
      sessionsForExercise(exerciseId).take(limit).toList();

  PerformedSet? bestSetBy1RM(int exerciseId) {
    PerformedSet? best;
    double best1rm = 0;

    for (final s in _allSets(exerciseId)) {
      final est = estimate1RM(weight: s.weight, reps: s.reps);
      if (est > best1rm) {
        best1rm = est;
        best = s;
      }
    }
    return best;
  }

  PersonalRecords prBaselines(int exerciseId) {
    double bestW = 0;
    int bestR = 0;
    double bestVol = 0;

    for (final s in _allSets(exerciseId)) {
      if (s.weight > bestW) bestW = s.weight;
      if (s.reps > bestR) bestR = s.reps;
      final v = s.weight * s.reps;
      if (v > bestVol) bestVol = v;
    }

    return PersonalRecords(
      bestWeight: bestW,
      bestReps: bestR,
      bestSetVolume: bestVol,
    );
  }

  List<(DateTime day, double value)> chartSeries({
    required int exerciseId,
    required ChartMetric metric,
    int maxPoints = 30,
  }) {
    final sessions = sessionsForExercise(exerciseId).take(maxPoints).toList()
      ..sort((a, b) => a.day.compareTo(b.day));

    double pick(ExerciseSessionSummary s) {
      switch (metric) {
        case ChartMetric.bestWeight:
          return s.bestWeight;
        case ChartMetric.bestEstimated1RM:
          return s.bestEstimated1RM;
      }
    }

    return sessions.map((s) => (s.day, pick(s))).toList();
  }

  Iterable<PerformedSet> _allSets(int exerciseId) sync* {
    for (final key in box.keys) {
      final entry = box.get(key);
      if (entry == null) continue;

      for (final log in entry.logs) {
        final int? id = _logExerciseId(log);
        if (id == null || id != exerciseId) continue;

        final sets = (log as dynamic).sets as List<dynamic>;
        for (final s in sets) {
          if (s is PerformedSet) yield s;
        }
      }
    }
  }
}

class _Agg {
  final DateTime day;
  DateTime endedAt;

  final List<PerformedSet> sets = [];

  double volume = 0;
  double bestW = 0;
  int bestR = 0;
  double best1rm = 0;

  _Agg({required this.day, required this.endedAt});

  ExerciseSessionSummary toSummary() => ExerciseSessionSummary(
        day: day,
        endedAt: endedAt,
        sets: List.unmodifiable(sets),
        sessionVolume: volume,
        bestWeight: bestW,
        bestReps: bestR,
        bestEstimated1RM: best1rm,
      );
}
