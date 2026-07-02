import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:workout_tracker/home/account/accountReposirtry.dart';
import 'package:workout_tracker/home/account/model/accountModel.dart';

class AccountViewModel extends ChangeNotifier {
  final AccountRepository repo;
  AccountViewModel(this.repo);

  AccountModel? _account;
  AccountModel? get account => _account;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  Future<void> load() async {
    _setLoading(true);
    try {
      _account = await repo.fetchMe();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh() => load();

  Future<void> update({String? displayName, String? username}) async {
    if (_account == null) return;
    _setLoading(true);
    try {
      _account = await repo.updateMe(
        displayName: displayName,
        username: username,
      );
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateAvatar(File file) async {
    _setLoading(true);
    try {
      _account = await repo.uploadAvatar(file);
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// Resets cached profile state. Call on sign-out so the next sign-in
  /// (possibly as a different user) doesn't briefly show stale data.
  void clear() {
    _account = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }
}
