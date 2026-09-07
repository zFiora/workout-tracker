import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_tracker/common/models/sex.dart';
import 'package:workout_tracker/common/units/weight_unit.dart';
import 'package:workout_tracker/home/measure/models/macro_profile.dart' show MacroProfile;
import 'package:workout_tracker/home/measure/repositeries/macros_profile_repository.dart';

enum SessionMode { offline, online }

class AppManager extends ChangeNotifier {
  SessionMode _mode = SessionMode.offline;
  ThemeMode _themeMode = ThemeMode.dark;
  Sex _sex = Sex.unspecified;
  WeightUnit _weightUnit = WeightUnit.kg;
  StreamSubscription? _macroProfileSub;

  bool get isOnline => _mode == SessionMode.online;
  bool get isOffline => _mode == SessionMode.offline;
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  /// Display/input unit for all weights. Storage stays canonical kg; this only
  /// affects presentation and entry (see [WeightUnit]). Persisted locally so
  /// it works fully offline and survives restarts.
  WeightUnit get weightUnit => _weightUnit;

  /// Drives sex-based theming (see `app_theme.dart`). Sourced from the same
  /// locally-persisted [MacroProfile] the Measures page writes to, so it
  /// works fully offline and survives app restarts without a second copy of
  /// the same preference living somewhere else.
  Sex get sex => _sex;

  AppManager() {
    _loadPrefs();
    _loadSex();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_mode');
    _themeMode = switch (saved) {
      'light' => ThemeMode.light,
      _ => ThemeMode.dark,
    };
    _weightUnit = WeightUnitX.fromName(prefs.getString('weight_unit'));
    notifyListeners();
  }

  Future<void> setWeightUnit(WeightUnit unit) async {
    if (_weightUnit == unit) return;
    _weightUnit = unit;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('weight_unit', unit.name);
  }

  void _loadSex() {
    _sex = MacrosProfileRepository().getProfile().sex;
    notifyListeners();

    // Stay in sync with changes made from the Measures page without either
    // view model needing to know about the other.
    if (Hive.isBoxOpen(MacrosProfileRepository.boxName)) {
      _macroProfileSub =
          Hive.box<MacroProfile>(MacrosProfileRepository.boxName).watch().listen((_) {
        final updated = MacrosProfileRepository().getProfile().sex;
        if (updated != _sex) {
          _sex = updated;
          notifyListeners();
        }
      });
    }
  }

  Future<void> toggleDarkMode(bool dark) async {
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', dark ? 'dark' : 'light');
  }

  void setOnline() {
    _mode = SessionMode.online;
    notifyListeners();
  }

  void setOffline() {
    _mode = SessionMode.offline;
    notifyListeners();
  }

  @override
  void dispose() {
    _macroProfileSub?.cancel();
    super.dispose();
  }
}
