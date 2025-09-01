// lib/auth/auth_service.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';
import '../core/pb.dart';

class AuthService {
  AuthService();

  final PocketBase _pb = PB.I.pb;

  bool get isLoggedIn => _pb.authStore.isValid;
  String? get userId => _pb.authStore.model?.id;

  /// Email/Username + password login
  Future<void> login(String emailOrUsername, String password) async {
    await _pb.collection('users').authWithPassword(emailOrUsername, password);
    await PB.I.persistAuth();
  }

  Future<void> register({
    required String email,
    required String username,
    required String password,
    required String displayName,
    File? avatarFile,
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'username': username,
      'password': password,
      'passwordConfirm': password,
      'name': displayName,
    };

    // Make it NON-nullable
    final files = <http.MultipartFile>[];
    if (avatarFile != null) {
      files.add(
        await http.MultipartFile.fromPath(
          'avatar',
          avatarFile.path,
        ), // field: users.avatar
      );
    }

    // Create user (pass empty list if no file was picked)
    await _pb.collection('users').create(body: body, files: files);

    // Login & persist
    await _pb.collection('users').authWithPassword(email, password);
    await PB.I.persistAuth();
  }

  /// Resend email verification to the given email
  Future<void> resendVerification(String email) async {
    await _pb.collection('users').requestVerification(email);
  }

  /// Logout and clear tokens everywhere (authStore + secure storage)
  Future<void> logout() async {
    await PB.I.clearAuthEverywhere();
  }
}
