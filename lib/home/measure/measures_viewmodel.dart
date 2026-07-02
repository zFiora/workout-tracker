import 'dart:math';
import 'package:flutter/material.dart';
import 'package:workout_tracker/home/measure/models/macroResults.dart';
import 'package:workout_tracker/home/measure/services/measures_api_service.dart';

import 'package:workout_tracker/home/measure/models/macro_profile.dart';
import 'package:workout_tracker/home/measure/models/measure_profile.dart';
import 'package:workout_tracker/home/measure/repositeries/macros_profile_repository.dart';
import 'package:workout_tracker/home/measure/repositeries/measures_profile_repository.dart';
import 'package:workout_tracker/home/measure/repositeries/measures_repository.dart';

import 'models/measurement_entry.dart';

class MeasuresViewModel extends ChangeNotifier {
  MeasuresViewModel(
    this._repo,
    this._profileRepo,
    this._macrosRepo, {
    MeasuresApiService? apiService,
  }) : _api = apiService ?? MeasuresApiService();

  final MeasuresRepository _repo;
  final MeasuresProfileRepository _profileRepo;
  final MacrosProfileRepository _macrosRepo;
  final MeasuresApiService _api;

  bool _loading = false;
  bool get loading => _loading;

  List<MeasurementEntry> _entries = [];
  List<MeasurementEntry> get entries => List.unmodifiable(_entries);

  MeasureProfile _profile = MeasureProfile(heightCm: null);
  MeasureProfile get profile => _profile;

  MacroProfile _macroProfile = MacroProfile.defaults;
  MacroProfile get macroProfile => _macroProfile;

  // ===== Derived (computed) =====
  double? get heightCm => _profile.heightCm;

  double? get latestWeight => _entries.isEmpty ? null : _entries.last.weightKg;

  double? get bmi {
    final w = latestWeight;
    final h = heightCm;
    if (w == null || h == null || w <= 0 || h <= 0) return null;
    final meters = h / 100.0;
    return w / (meters * meters);
  }

  (double min, double max) get weightRange {
    if (_entries.isEmpty) return (0, 0);
    final minW = _entries.map((e) => e.weightKg).reduce(min);
    final maxW = _entries.map((e) => e.weightKg).reduce(max);
    const pad = 1.0;
    return (minW - pad, maxW + pad);
  }

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
    final cutting = (tdee - 500).round();
    final bulking = (tdee + 250).round();

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

  // ===== Load =====
  Future<void> load() async {
    _loading = true;
    notifyListeners();

    try {
      _profile = _profileRepo.getProfile();
      _macroProfile = _macrosRepo.getProfile();
      _entries = await _repo.getAll();
      _sortEntries();

      // Best-effort background sync — never fails the load
      _syncFromApi().ignore();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _syncFromApi() async {
    try {
      final remote = await _api.fetchMeasurements();
      for (final e in remote) {
        await _repo.upsert(e);
      }
      _entries = await _repo.getAll();
      _sortEntries();

      final remoteMacro = await _api.fetchMacroProfile();
      _macroProfile = remoteMacro;
      await _macrosRepo.saveProfile(remoteMacro);

      notifyListeners();
    } catch (_) {
      // offline or auth error — local data is still shown
    }
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
    _api.putMacroProfile(_macroProfile).ignore();
  }

  Future<void> setAge(int age) async {
    final clean = age.clamp(10, 90);
    _macroProfile = _macroProfile.copyWith(age: clean);
    await _macrosRepo.saveProfile(_macroProfile);
    notifyListeners();
    _api.putMacroProfile(_macroProfile).ignore();
  }

  Future<void> setActivityFactor(double factor) async {
    _macroProfile = _macroProfile.copyWith(activityFactor: factor);
    await _macrosRepo.saveProfile(_macroProfile);
    notifyListeners();
    _api.putMacroProfile(_macroProfile).ignore();
  }

  // ===== Weight stats =====
  /// Difference between latest weight and the closest entry at/BEFORE (latest - days).
  double? deltaDays(int days) {
    if (_entries.isEmpty) return null;

    final latest = _entries.last;
    final target = latest.date.toLocal().subtract(Duration(days: days));

    // Entries sorted ascending by date.
    // Find closest entry with date <= target (search backwards).
    MeasurementEntry? candidate;
    for (int i = _entries.length - 1; i >= 0; i--) {
      final d = _entries[i].date.toLocal();
      if (!d.isAfter(target)) {
        candidate = _entries[i];
        break;
      }
    }

    candidate ??= _entries.first;
    return latest.weightKg - candidate.weightKg;
  }

  /// Adds a new entry, or replaces an existing entry on the same local day.
  Future<void> addOrReplaceEntry({
    required double weightKg,
    required DateTime dateLocal,
  }) async {
    final existing = _findByLocalDay(dateLocal);

    var entry = MeasurementEntry(
      id: existing?.id ?? _uuid(),
      date: dateLocal.toUtc(),
      weightKg: weightKg,
    );

    // Push to API and use server-assigned id if available
    try {
      final saved = await _api.postMeasurement(entry);
      entry = saved;
    } catch (_) {}

    await _repo.upsert(entry);

    if (existing == null) {
      _entries.add(entry);
    } else {
      final idx = _entries.indexWhere((e) => e.id == existing.id);
      if (idx != -1) _entries[idx] = entry;
    }

    _sortEntries();
    notifyListeners();
  }

  Future<void> deleteEntry(String id) async {
    try {
      await _api.deleteMeasurement(id);
    } catch (_) {}

    await _repo.deleteById(id);
    _entries.removeWhere((e) => e.id == id);
    _sortEntries();
    notifyListeners();
  }

  // ===== Helpers =====
  void _sortEntries() {
    _entries.sort((a, b) => a.date.compareTo(b.date)); // ascending
  }

  MeasurementEntry? _findByLocalDay(DateTime dateLocal) {
    for (final e in _entries) {
      if (_sameLocalDay(e.date.toLocal(), dateLocal)) return e;
    }
    return null;
  }

  bool _sameLocalDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _uuid() {
    final ms = DateTime.now().microsecondsSinceEpoch;
    final rnd = Random().nextInt(1 << 20);
    return '$ms-$rnd';
  }
}
