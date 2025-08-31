import 'package:pocketbase/pocketbase.dart';
import '../core/pb.dart';

class AuthService {
  final PocketBase _pb = PB.I.pb;

  bool get isLoggedIn => _pb.authStore.isValid;
  String? get userId => _pb.authStore.model?.id;

  Future<void> login(String emailOrUsername, String password) async {
    await _pb.collection('users').authWithPassword(emailOrUsername, password);
    await PB.I.persistAuth();
  }

  Future<void> register({
    required String email,
    required String username,
    required String password,
    String? name,
  }) async {
    await _pb
        .collection('users')
        .create(
          body: {
            'email': email,
            'password': password,
            'passwordConfirm': password,
            'username': username,
            if (name != null && name.isNotEmpty) 'name': name,
          },
        );

    try {
      await _pb.collection('users').authWithPassword(email, password);
      await PB.I.persistAuth();
    } on ClientException {
      rethrow;
    }
  }

  Future<void> resendVerification(String email) async {
    await _pb.collection('users').requestVerification(email);
  }

  Future<void> logout() async {
    await PB.I.clearAuthEverywhere();
  }
}
