import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:workout_tracker/auth/authService.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._auth);
  final AuthService _auth;

  bool _busy = false;
  String? _error;

  bool get busy => _busy;
  String? get error => _error;
  bool get isLoggedIn => _auth.isLoggedIn;

  Future<bool> login(String emailOrUsername, String password) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _auth.login(emailOrUsername, password);
      return true;
    } on ClientException catch (e) {
      _error = e.response['message']?.toString() ?? 'Login failed';
      return false;
    } catch (e, st) {
      debugPrint('Login error: $e\n$st');
      _error = 'Something went wrong. Please try again.';
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
    File? avatarFile,
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
        avatarFile: avatarFile,
      );
      return true; // auto-logged in if verification not enforced
    } on ClientException catch (e) {
      _error = e.response['message']?.toString() ?? 'Registration failed';
      return false;
    } catch (e, st) {
      debugPrint('Register error: $e\n$st');
      _error = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> resendVerification(String email) async {
    try {
      await _auth.resendVerification(email);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.logout();
    notifyListeners();
  }
}
