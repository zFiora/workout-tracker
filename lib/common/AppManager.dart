import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SessionMode { offline, online }

class AppManager extends ChangeNotifier {
  SessionMode _mode = SessionMode.offline;
  ThemeMode _themeMode = ThemeMode.dark;

  bool get isOnline => _mode == SessionMode.online;
  bool get isOffline => _mode == SessionMode.offline;
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  AppManager() {
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_mode');
    _themeMode = switch (saved) {
      'light' => ThemeMode.light,
      _ => ThemeMode.dark,
    };
    notifyListeners();
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
}
