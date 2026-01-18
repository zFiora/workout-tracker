import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:workout_tracker/home/history/models/PRModels.dart';
import 'package:workout_tracker/home/history/models/exNote.dart';
import 'package:workout_tracker/home/history/repos/exHistoryRepo.dart';
import 'package:workout_tracker/home/history/utils/strengthUtils.dart';

import '../../session/models/sessionModels.dart';

class ExerciseDetailViewModel extends ChangeNotifier {
  ExerciseDetailViewModel({
    required this.exerciseId,
    required this.historyRepo,
    required this.notesBox,
  }) {
    _refresh();
    _notesSub = notesBox.watch().listen((_) {
      _refreshNotes();
      notifyListeners();
    });
  }

  final int exerciseId;
  final ExerciseHistoryRepository historyRepo;
  final Box<ExerciseNote> notesBox;

  late final StreamSubscription _notesSub;

  ChartMetric metric = ChartMetric.bestWeight;

  PerformedSet? bestSet;
  double bestSetEstimated1RM = 0;

  PersonalRecords prs = const PersonalRecords.empty();
  List<ExerciseSessionSummary> last5 = const [];
  List<(DateTime day, double value)> series = const [];

  List<ExerciseNote> notes = const [];

  void setMetric(ChartMetric m) {
    metric = m;
    series = historyRepo.chartSeries(exerciseId: exerciseId, metric: metric);
    notifyListeners();
  }

  Future<void> addNote(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;

    await notesBox.add(ExerciseNote(
      exerciseId: exerciseId,
      createdAt: DateTime.now(),
      text: t,
    ));
  }

  void _refresh() {
    bestSet = historyRepo.bestSetBy1RM(exerciseId);
    if (bestSet != null) {
      bestSetEstimated1RM = estimate1RM(weight: bestSet!.weight, reps: bestSet!.reps);
    } else {
      bestSetEstimated1RM = 0;
    }

    prs = historyRepo.prBaselines(exerciseId);
    last5 = historyRepo.lastSessions(exerciseId, limit: 5);
    series = historyRepo.chartSeries(exerciseId: exerciseId, metric: metric);
    _refreshNotes();
  }

  void _refreshNotes() {
    final all = notesBox.values.where((n) => n.exerciseId == exerciseId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notes = List.unmodifiable(all);
  }

  @override
  void dispose() {
    _notesSub.cancel();
    super.dispose();
  }
}
