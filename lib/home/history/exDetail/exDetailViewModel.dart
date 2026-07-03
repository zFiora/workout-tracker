import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:workout_tracker/home/history/models/PRModels.dart';
import 'package:workout_tracker/home/history/models/exNote.dart';
import 'package:workout_tracker/home/history/repos/exHistoryRepo.dart';
import 'package:workout_tracker/home/history/services/exercise_notes_api_service.dart';
import 'package:workout_tracker/home/history/utils/strengthUtils.dart';

import '../../session/models/sessionModels.dart';

class ExerciseDetailViewModel extends ChangeNotifier {
  ExerciseDetailViewModel({
    required this.exerciseId,
    required this.historyRepo,
    required this.notesBox,
    ExerciseNotesApiService? notesApi,
  }) : _notesApi = notesApi ?? ExerciseNotesApiService() {
    _refresh();
    _notesSub = notesBox.watch().listen((_) {
      _refreshNotes();
      notifyListeners();
    });
    _loadNotesFromApi();
  }

  final int exerciseId;
  final ExerciseHistoryRepository historyRepo;
  final Box<ExerciseNote> notesBox;
  final ExerciseNotesApiService _notesApi;

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

    try {
      // Backend is the source of truth; cache the server's note.
      final created = await _notesApi.create(exerciseId, t);
      await notesBox.add(created);
    } catch (_) {
      // Offline — keep the note locally so it isn't lost this session.
      await notesBox.add(ExerciseNote(
        exerciseId: exerciseId,
        createdAt: DateTime.now(),
        text: t,
      ));
    }
  }

  /// Backend-authoritative pull: replaces this exercise's cached notes with
  /// the server's. Runs only after a successful fetch, so offline keeps cache.
  Future<void> _loadNotesFromApi() async {
    try {
      final remote = await _notesApi.fetch(exerciseId);
      final staleKeys = notesBox.keys.where((k) {
        final n = notesBox.get(k);
        return n != null && n.exerciseId == exerciseId;
      }).toList();
      for (final k in staleKeys) {
        await notesBox.delete(k);
      }
      for (final n in remote) {
        await notesBox.add(n);
      }
      // notesBox.watch() refreshes the list + notifies.
    } catch (_) {
      // offline or auth error — cached notes stay visible
    }
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
