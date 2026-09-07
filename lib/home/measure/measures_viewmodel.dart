import 'dart:math';
import 'package:flutter/material.dart';
import 'package:workout_tracker/home/measure/models/macroResults.dart';
import 'package:workout_tracker/home/measure/services/measures_api_service.dart';

import 'package:workout_tracker/home/measure/models/macro_profile.dart';
import 'package:workout_tracker/home/measure/models/measure_profile.dart';
import 'package:workout_tracker/home/measure/repositeries/macros_profile_repository.dart';
import 'package:workout_tracker/home/measure/repositeries/measures_profile_repository.dart';
import 'package:workout_tracker/home/measure/repositeries/measures_repository.dart';
import 'package:workout_tracker/home/measure/repositeries/pending_measurement_deletes_store.dart';
import 'package:workout_tracker/home/measure/repositeries/synced_measurements_store.dart';

import 'models/measurement_entry.dart';

class MeasuresViewModel extends ChangeNotifier {
  MeasuresViewModel(
    this._repo,
    this._profileRepo,
    this._macrosRepo, {
    MeasuresApiService? apiService,
    SyncedMeasurementsStore? syncedStore,
    PendingMeasurementDeletesStore? pendingDeletesStore,
  }) : _api = apiService ?? MeasuresApiService(),
       _synced = syncedStore ?? SyncedMeasurementsStore(),
       _pendingDeletes = pendingDeletesStore ?? PendingMeasurementDeletesStore();

  final MeasuresRepository _repo;
  final MeasuresProfileRepository _profileRepo;
  final MacrosProfileRepository _macrosRepo;
  final MeasuresApiService _api;
  final SyncedMeasurementsStore _synced;
  final PendingMeasurementDeletesStore _pendingDeletes;

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

  /// Reconciles with the backend. Runs only after a successful fetch, so
  /// offline/failed requests leave the cache untouched.
  ///
  /// A local entry is only dropped when the server has *confirmed* deleting
  /// it (i.e. it was synced before and is now missing remotely) — an
  /// offline-created entry that hasn't been pushed yet is never mistaken for
  /// a server-side delete and wiped out from under the user.
  Future<void> _syncFromApi() async {
    try {
      // Flush any deletes that couldn't reach the server last time, before
      // pulling — otherwise a still-present remote row would get re-added.
      for (final id in await _pendingDeletes.all()) {
        try {
          await _api.deleteMeasurement(id);
          await _pendingDeletes.remove(id);
          await _synced.forget(id);
        } catch (_) {}
      }
      final stillPendingDelete = await _pendingDeletes.all();

      final remote = (await _api.fetchMeasurements())
          .where((e) => !stillPendingDelete.contains(e.id))
          .toList();
      final remoteIds = remote.map((e) => e.id).toSet();

      final localAll = await _repo.getAll();
      for (final e in localAll) {
        if (!remoteIds.contains(e.id) && _synced.isSynced(e.id)) {
          await _repo.deleteById(e.id);
          await _synced.forget(e.id);
        }
      }
      for (final e in remote) {
        await _repo.upsert(e);
        await _synced.markSynced(e.id);
      }

      // Push local entries the server doesn't have yet (offline-created).
      final stillLocal = await _repo.getAll();
      for (final e in stillLocal) {
        if (remoteIds.contains(e.id)) continue;
        try {
          final saved = await _api.postMeasurement(e);
          if (saved.id != e.id) {
            await _repo.deleteById(e.id);
          }
          await _repo.upsert(saved);
          await _synced.markSynced(saved.id);
        } catch (_) {
          // still offline/failed — leave it pending for next sync
        }
      }

      _entries = await _repo.getAll();
      _sortEntries();

      // Macro profile + height come from one backend resource. Sex/DOB
      // aren't backend fields yet, so the current local profile is passed
      // as a fallback the fetch can't accidentally null out.
      final profile = await _api.fetchProfile(fallback: _macroProfile);
      _macroProfile = profile.macro;
      await _macrosRepo.saveProfile(profile.macro);
      _profile = MeasureProfile(heightCm: profile.heightCm);
      await _profileRepo.saveProfile(_profile);

      notifyListeners();
    } catch (_) {
      // offline or auth error — local data is still shown
    }
  }

  // ===== Profile setters =====
  // Height and macro inputs share one backend row, so every setter pushes the
  // whole profile (a PUT is a full replace) via [_pushProfile].
  Future<void> setHeightCm(double? height) async {
    final clean = (height == null || height <= 0) ? null : height;
    // Construct directly — copyWith can't set heightCm back to null.
    _profile = MeasureProfile(heightCm: clean);
    await _profileRepo.saveProfile(_profile);
    notifyListeners();
    _pushProfile();
  }

  /// Sets sex for profile/theming/BMR purposes (the source of truth going
  /// forward — [MacroProfile.isMale] is kept as an internal mirror only for
  /// backend/BMR compatibility, see [MacroProfile.withSex]).
  Future<void> setSex(Sex sex) async {
    _macroProfile = _macroProfile.withSex(sex);
    await _macrosRepo.saveProfile(_macroProfile);
    notifyListeners();
    _pushProfile();
  }

  /// Primary way to set age going forward — [MacroProfile.age] is always
  /// computed from this once set, never manually re-entered.
  Future<void> setDateOfBirth(DateTime dobLocal) async {
    _macroProfile = _macroProfile.withDateOfBirth(dobLocal);
    await _macrosRepo.saveProfile(_macroProfile);
    notifyListeners();
    _pushProfile();
  }

  /// Legacy manual-age fallback, only meaningful for accounts that haven't
  /// set a date of birth yet — once a DOB exists, [MacroProfile.age] ignores
  /// this and this setter is unreachable from the UI.
  Future<void> setAgeFallback(int age) async {
    final clean = age.clamp(10, 90);
    _macroProfile = _macroProfile.copyWith(age: clean);
    await _macrosRepo.saveProfile(_macroProfile);
    notifyListeners();
    _pushProfile();
  }

  Future<void> setActivityFactor(double factor) async {
    _macroProfile = _macroProfile.copyWith(activityFactor: factor);
    await _macrosRepo.saveProfile(_macroProfile);
    notifyListeners();
    _pushProfile();
  }

  /// Pushes the combined macro + height profile to the backend (best-effort).
  void _pushProfile() {
    _api
        .putProfile(macro: _macroProfile, heightCm: _profile.heightCm)
        .ignore();
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

    // Push to API and use server-assigned id if available. Left unsynced
    // (and so still shown, still pending) on failure — never dropped.
    try {
      final saved = await _api.postMeasurement(entry);
      entry = saved;
      await _synced.markSynced(saved.id);
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
    // Remove locally first — the user's intent is honored immediately
    // regardless of connectivity.
    await _repo.deleteById(id);
    _entries.removeWhere((e) => e.id == id);
    _sortEntries();
    notifyListeners();

    try {
      await _api.deleteMeasurement(id);
      await _synced.forget(id);
    } catch (_) {
      // Remembered so the next sync doesn't pull this id back down.
      await _pendingDeletes.add(id);
    }
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
