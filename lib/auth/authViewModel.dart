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
}
