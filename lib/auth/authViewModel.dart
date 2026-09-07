import 'package:flutter/foundation.dart';
import 'package:workout_tracker/auth/authService.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._auth);
  final AuthService _auth;

  bool _busy = false;
  String? _error;

  bool get busy => _busy;
  String? get error => _error;
  bool get isLoggedIn => _auth.isLoggedIn;

  Future<bool> login(String identity, String password) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _auth.login(identity, password);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String email,
    required String username,
    required String password,
    required String displayName,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _auth.register(
        email: email,
        username: username,
        password: password,
        displayName: displayName,
      );
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.logout();
    notifyListeners();
  }

  /// Returns null on success, or an error message (e.g. "Incorrect password.")
  /// on failure.
  Future<String?> deleteAccount(String password) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _auth.deleteAccount(password);
      return null;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      _error = message;
      return message;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Returns null on success, or an error message on failure.
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _auth.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return null;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      _error = message;
      return message;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Always "succeeds" from the caller's point of view — the UI shows the
  /// same generic "check your email" message whether or not the address is
  /// registered, so this can't be used to enumerate accounts. A network
  /// failure (no connection, server down) is the only thing surfaced back.
  Future<String?> requestPasswordReset(String email) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _auth.requestPasswordReset(email);
      return null;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      _error = message;
      return message;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Returns null on success, or an error message (expired/used/invalid
  /// token, weak password, ...) on failure.
  Future<String?> confirmPasswordReset({
    required String token,
    required String newPassword,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _auth.confirmPasswordReset(token: token, newPassword: newPassword);
      return null;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      _error = message;
      return message;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
