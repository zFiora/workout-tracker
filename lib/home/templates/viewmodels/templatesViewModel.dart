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

  Future<void> _pullFromApi() async {
    try {
      final remote = await _api.fetchMine();
      final localIds = _repo.getAllSorted().map((t) => t.id).toSet();
      for (final template in remote) {
        if (!localIds.contains(template.id)) {
          await _repo.add(template);
        }
      }
      notifyListeners();
    } catch (_) {
      // offline or auth error — local templates are still shown
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
