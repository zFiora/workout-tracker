// lib/auth/auth_service.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';
import '../core/pb.dart'; // for PB.I.persistAuth() / clearAuthEverywhere()

class AuthService {
  AuthService(this._pb);

  final PocketBase _pb;

  bool get isLoggedIn => _pb.authStore.isValid && _pb.authStore.model != null;
  String? get userId => _pb.authStore.record?.id;

  /// Email/Username + password login
  Future<void> login(String emailOrUsername, String password) async {
    await _pb.collection('users').authWithPassword(emailOrUsername, password);
    await PB.I.persistAuth(); // save token to secure storage
  }

  /// Register a user in `users`, then create their `profiles` row
  /// Assumes you have a `profiles` collection with fields:
  /// - user (relation -> _pb_users_auth_)
  /// - displayName (text)
  /// - username (text)
  /// - avatar (file)
  Future<void> register({
    required String email,
    required String username,
    required String password,
    required String displayName,
    File? avatarFile,
  }) async {
    // 1) Create user (users collection)
    await _pb
        .collection('users')
        .create(
          body: {
            'email': email,
            'username': username,
            'password': password,
            'passwordConfirm': password,
          },
        );

    // 2) Login so we have a token & user model
    await _pb.collection('users').authWithPassword(email, password);
    await PB.I.persistAuth();

    // 3) Create profile linked to the authed user
    final uid = _pb.authStore.record!.id;

    final files = <http.MultipartFile>[];
    if (avatarFile != null) {
      files.add(await http.MultipartFile.fromPath('avatar', avatarFile.path));
    }

    await _pb
        .collection('profiles')
        .create(
          body: {'user': uid, 'displayName': displayName, 'username': username},
          files: files, // empty list is fine
        );
  }

  /// Resend email verification (if you enforce verification)
  Future<void> resendVerification(String email) async {
    await _pb.collection('users').requestVerification(email);
  }

  /// Logout and clear tokens everywhere (authStore + secure storage)
  Future<void> logout() async {
    await PB.I.clearAuthEverywhere();
  }
}
