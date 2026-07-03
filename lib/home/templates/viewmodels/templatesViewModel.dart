import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:workout_tracker/home/templates/models/workout_template.dart';
import 'package:workout_tracker/home/templates/repositories/hiveTemplatesRepositories.dart';
import 'package:workout_tracker/home/templates/repositories/templatesRepositories.dart';
import 'package:workout_tracker/home/templates/services/templates_api_service.dart';

class TemplatesViewModel extends ChangeNotifier {
  TemplatesViewModel({TemplatesRepository? repo, TemplatesApiService? api})
    : _repo = repo ?? HiveTemplatesRepository(),
      _api = api ?? TemplatesApiService() {
    // Auto-refresh UI when the Hive box changes (add/put/delete)
    _sub = Hive.box<WorkoutTemplateModel>(
      'templatesBox',
    ).watch().listen((_) => notifyListeners());

    _pullFromApi();
  }

  final TemplatesRepository _repo;
  final TemplatesApiService _api;
  StreamSubscription<BoxEvent>? _sub;

  /// Two-way reconcile with last-writer-wins by `updatedAt`. Runs only after a
  /// successful fetch, so an offline/failed request leaves the cache untouched.
  ///
  /// - Server-deleted templates are removed locally (identified via the
  ///   deleted-ids feed, so offline-created locals are never mistaken for them).
  /// - Newer server edits are applied locally; newer local edits (or templates
  ///   the server hasn't seen) are pushed up.
  Future<void> _pullFromApi() async {
    try {
      final remote = await _api.fetchMine(); // active only
      final remoteById = {for (final t in remote) t.id: t};

      // Deleted-ids is a best-effort refinement; without it we simply don't
      // propagate remote deletes this pass (never wrongly drop a local).
      Set<String> deletedIds = {};
      try {
        deletedIds = await _api.fetchDeletedIds();
      } catch (_) {}

      // 1) Apply server-side deletes.
      for (final local in _repo.getAllSorted()) {
        if (deletedIds.contains(local.id)) {
          await _repo.delete(local);
        }
      }

      // 2) Apply server templates that are newer-or-equal to the local copy.
      for (final r in remote) {
        final local = _repo.byId(r.id);
        if (local == null || !r.updatedAt.isBefore(local.updatedAt)) {
          await _repo.upsert(r);
        }
      }

      // 3) Push locals the server is missing, or that are newer locally
      //    (offline creates/edits). Skip anything the server deleted.
      for (final local in _repo.getAllSorted()) {
        if (deletedIds.contains(local.id)) continue;
        final r = remoteById[local.id];
        if (r == null || local.updatedAt.isAfter(r.updatedAt)) {
          _api.pushUpsert(local).catchError((_) {});
        }
      }

      notifyListeners();
    } catch (_) {
      // offline or auth error — cached templates are still shown
    }
  }

  List<WorkoutTemplateModel> get templates => _repo.getAllSorted();

  WorkoutTemplateModel? byId(String id) => _repo.byId(id);

  Future<void> addTemplate(WorkoutTemplateModel template) async {
    await _repo.add(template);
    notifyListeners();
    _api.pushUpsert(template).catchError((_) {});
  }

  Future<void> deleteTemplate(WorkoutTemplateModel template) async {
    await _repo.delete(template);
    notifyListeners();
    _api.deleteRemote(template.id).catchError((_) {});
  }

  Future<void> renameTemplate(
    WorkoutTemplateModel template,
    String newName,
  ) async {
    await _repo.rename(template, newName);
    notifyListeners();
    _pushUpdated(template.id);
  }

  Future<void> changeIconPath(
    WorkoutTemplateModel template,
    String newIconPath,
  ) async {
    await _repo.changeIconPath(template, newIconPath);
    notifyListeners();
    _pushUpdated(template.id);
  }

  Future<void> updateExercises(
    WorkoutTemplateModel template,
    List<int> newExerciseIds,
  ) async {
    await _repo.updateExercises(template, newExerciseIds);
    notifyListeners();
    _pushUpdated(template.id);
  }

  void _pushUpdated(String id) {
    final updated = _repo.byId(id);
    if (updated != null) _api.pushUpsert(updated).catchError((_) {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
