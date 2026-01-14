import 'dart:math';
import 'package:flutter/material.dart';

import 'package:workout_tracker/home/measure/models/macro_profile.dart';
import 'package:workout_tracker/home/measure/repositeries/macros_profile_repository.dart';

// ⚠️ Keep your current import path if that's where your MeasureProfile is.
// If you actually created it under home/measure/models, then change this import.
import 'package:workout_tracker/home/session/models/measure_profile.dart';

import 'models/measurement_entry.dart';
import 'repositeries/measures_repository.dart';
import 'repositeries/measures_profile_repository.dart';

class MeasuresViewModel extends ChangeNotifier {
  MeasuresViewModel(this._repo, this._profileRepo, this._macrosRepo);

  final MeasuresRepository _repo;
  final MeasuresProfileRepository _profileRepo;
  final MacrosProfileRepository _macrosRepo;

  bool _loading = false;
  bool get loading => _loading;

  List<MeasurementEntry> _entries = [];
  List<MeasurementEntry> get entries => List.unmodifiable(_entries);

  MeasureProfile _profile = MeasureProfile(heightCm: null);
  MeasureProfile get profile => _profile;

  MacroProfile _macroProfile = MacroProfile.defaults;
  MacroProfile get macroProfile => _macroProfile;

  // ===== Height / BMI =====
  double? get heightCm => _profile.heightCm;

  double? get latestWeight => _entries.isEmpty ? null : _entries.last.weightKg;

  double? get bmi {
    final w = latestWeight;
    final h = heightCm;
    if (w == null || h == null || w <= 0 || h <= 0) return null;
    final meters = h / 100.0;
    return w / (meters * meters);
  }

  // ===== Load =====
  Future<void> load() async {
    _loading = true;
    notifyListeners();

    _profile = _profileRepo.getProfile();
    _macroProfile = _macrosRepo.getProfile();
    _entries = await _repo.getAll();

    _loading = false;
    notifyListeners();
  }

  // ===== Profile setters =====
  Future<void> setHeightCm(double? height) async {
    final clean = (height == null || height <= 0) ? null : height;
    _profile = _profile.copyWith(heightCm: clean);
    await _profileRepo.saveProfile(_profile);
    notifyListeners();
  }

  Future<void> setIsMale(bool isMale) async {
    _macroProfile = _macroProfile.copyWith(isMale: isMale);
    await _macrosRepo.saveProfile(_macroProfile);
    notifyListeners();
  }

  Future<void> setAge(int age) async {
    final clean = age.clamp(10, 90);
    _macroProfile = _macroProfile.copyWith(age: clean);
    await _macrosRepo.saveProfile(_macroProfile);
    notifyListeners();
  }

  Future<void> setActivityFactor(double factor) async {
    _macroProfile = _macroProfile.copyWith(activityFactor: factor);
    await _macrosRepo.saveProfile(_macroProfile);
    notifyListeners();
  }

  // ===== Weight stats =====
  double? deltaDays(int days) {
    if (_entries.isEmpty) return null;

    final latest = _entries.last;
    final target = latest.date.toLocal().subtract(Duration(days: days));

    MeasurementEntry? closest;

    for (final e in _entries) {
      if (e.date.toLocal().isBefore(target)) continue;
      closest = e;
      break;
    }

    closest ??= _entries.first;
    return latest.weightKg - closest.weightKg;
  }

  Future<void> addOrReplaceEntry({
    required double weightKg,
    required DateTime dateLocal,
  }) async {
    final entry = MeasurementEntry(
      id: _uuid(),
      date: dateLocal.toUtc(),
      weightKg: weightKg,
    );

    await _repo.upsert(entry);
    await load();
  }

  Future<void> deleteEntry(String id) async {
    await _repo.deleteById(id);
    await load();
  }

  (double min, double max) get weightRange {
    if (_entries.isEmpty) return (0, 0);
    final minW = _entries.map((e) => e.weightKg).reduce(min);
    final maxW = _entries.map((e) => e.weightKg).reduce(max);
    const pad = 1.0;
    return (minW - pad, maxW + pad);
  }

  // ===== Macros =====
  MacroPack? get macrosPack {
    final w = latestWeight;
    final h = heightCm;
    if (w == null || h == null || w <= 0 || h <= 0) return null;

    final age = _macroProfile.age;

    // Mifflin-St Jeor BMR
    final bmr = 10 * w + 6.25 * h - 5 * age + (_macroProfile.isMale ? 5 : -161);

    // TDEE
    final tdee = bmr * _macroProfile.activityFactor;

    final maintenance = tdee.round();
    final cutting = (tdee - 500).round(); // default cut
    final bulking = (tdee + 250).round(); // lean bulk

    MacroResult buildPlan(int calories, double proteinPerKg) {
      final proteinG = (proteinPerKg * w).round();
      final fatG = (0.8 * w).round();

      final proteinCals = proteinG * 4;
      final fatCals = fatG * 9;

      final remaining = calories - proteinCals - fatCals;
      final carbsG = (remaining / 4).floor().clamp(0, 9999);

      return MacroResult(
        calories: calories,
        proteinG: proteinG,
        carbsG: carbsG,
        fatG: fatG,
      );
    }

    return MacroPack(
      maintenance: buildPlan(maintenance, 1.8),
      cutting: buildPlan(cutting, 2.2),
      bulking: buildPlan(bulking, 1.6),
    );
  }

  // ===== Utils =====
  String _uuid() {
    final ms = DateTime.now().microsecondsSinceEpoch;
    final rnd = Random().nextInt(1 << 20);
    return '$ms-$rnd';
  }
}

class MacroResult {
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;

  const MacroResult({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });
}

class MacroPack {
  final MacroResult maintenance;
  final MacroResult cutting;
  final MacroResult bulking;

  const MacroPack({
    required this.maintenance,
    required this.cutting,
    required this.bulking,
  });
}
