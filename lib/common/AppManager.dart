import 'package:flutter/foundation.dart';

enum SessionMode { offline, online }

class AppManager extends ChangeNotifier {
  SessionMode _mode = SessionMode.offline;

  bool get isOnline => _mode == SessionMode.online;
  bool get isOffline => _mode == SessionMode.offline;

  void setOnline() {
    _mode = SessionMode.online;
    notifyListeners();
  }

  void setOffline() {
    _mode = SessionMode.offline;
    notifyListeners();
  }
}
