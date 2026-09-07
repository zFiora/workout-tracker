import 'package:flutter/material.dart';
import 'package:workout_tracker/common/units/weight_unit.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

class PlannedSetControllers {
  // Controllers keyed by stable row key (exerciseId:identityHashCode(plannedSet))
  final Map<String, TextEditingController> _wCtrls = {};
  final Map<String, TextEditingController> _rCtrls = {};
  final Set<String> _initialized = {};

  String rowKey(int exerciseId, PlannedSet p) =>
      '$exerciseId:${identityHashCode(p)}';

  TextEditingController weightCtrl(String rowKey) =>
      _wCtrls.putIfAbsent(rowKey, () => TextEditingController());

  TextEditingController repsCtrl(String rowKey) =>
      _rCtrls.putIfAbsent(rowKey, () => TextEditingController());

  // Weight is stored in kg; the text field shows it in the user's unit.
  String _weightText(double? kg, WeightUnit unit) =>
      kg == null ? '' : unit.format(kg);

  void initOnce({
    required String rowKey,
    required PlannedSet p,
    required WeightUnit unit,
  }) {
    if (_initialized.contains(rowKey)) return;

    final w = weightCtrl(rowKey);
    final r = repsCtrl(rowKey);

    w.text = _weightText(p.weight, unit);
    r.text = p.reps == null ? '' : p.reps!.toString();

    _initialized.add(rowKey);
  }

  void resetToModel({
    required String rowKey,
    required PlannedSet p,
    required WeightUnit unit,
  }) {
    weightCtrl(rowKey).text = _weightText(p.weight, unit);
    repsCtrl(rowKey).text = p.reps == null ? '' : p.reps!.toString();
  }

  void cleanupForExercise({
    required int exerciseId,
    required List<PlannedSet> planned,
    required Set<String> editingKeys,
  }) {
    final valid = planned.map((p) => rowKey(exerciseId, p)).toSet();

    final toRemove = _wCtrls.keys
        .where((k) => k.startsWith('$exerciseId:') && !valid.contains(k))
        .toList();

    for (final k in toRemove) {
      _wCtrls.remove(k)?.dispose();
      _rCtrls.remove(k)?.dispose();
      editingKeys.remove(k);
      _initialized.remove(k);
    }
  }

  void dispose() {
    for (final c in _wCtrls.values) {
      c.dispose();
    }
    for (final c in _rCtrls.values) {
      c.dispose();
    }
    _wCtrls.clear();
    _rCtrls.clear();
    _initialized.clear();
  }
}
