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

  /// True when [account] is a locally-cached last-known profile that hasn't
  /// been confirmed against the server yet this session (e.g. offline / the
  /// server is unreachable). The UI shows a "not synced" hint rather than an
  /// error screen in this case — cached data is still useful.
  bool _isStale = false;
  bool get isStale => _isStale;

  /// Cache-first load: shows the last-known profile immediately (including
  /// fully offline, on a cold start), then reconciles with the server.
  /// A failed server fetch never clears already-shown cached data.
  Future<void> load() async {
    if (_account == null) {
      final cached = await repo.readCached();
      if (cached != null) {
        _account = cached;
        _isStale = true;
        notifyListeners();
      }
    }

    _setLoading(true);
    try {
      _account = await repo.fetchMe();
      _isStale = false;
      _error = null;
    } catch (e) {
      // Keep showing cached data (if any) instead of blowing it away.
      if (_account == null) {
        _error = e.toString().replaceFirst('Exception: ', '');
      } else {
        _isStale = true;
      }
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
      _isStale = false;
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
      _isStale = false;
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
    _isStale = false;
    _loading = false;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }
}
