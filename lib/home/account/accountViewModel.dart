import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh() => load();

  Future<void> update({
    String? displayName,
    String? username,
    File? avatarFile,
  }) async {
    if (_account == null) return;

    // If nothing to update, skip the call
    final nothingToUpdate =
        (displayName == null || displayName == _account!.displayName) &&
        (username == null || username == _account!.username) &&
        avatarFile == null;
    if (nothingToUpdate) return;

    _setLoading(true);
    try {
      // Build files list (non-nullable)
      final files = <http.MultipartFile>[];
      if (avatarFile != null) {
        files.add(await http.MultipartFile.fromPath('avatar', avatarFile.path));
      }

      _account = await repo.updateMe(
        displayName: displayName,
        username: username,
        files: files, 
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
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

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }
}
