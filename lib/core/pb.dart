import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pocketbase/pocketbase.dart';

class PB {
  PB._();
  static final PB I = PB._();

  static const String baseUrl = "http://10.0.2.2:8090";

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final PocketBase pb = PocketBase(baseUrl);

  /// Restore session on app start
  Future<void> bootstrapAuth() async {
    final token = await _storage.read(key: 'pb_token');
    if (token == null) return;

    // Load token first; we’ll refresh to get the user model.
    pb.authStore.save(token, null);
    try {
      // Default auth collection is 'users'
      await pb.collection('users').authRefresh();
    } catch (_) {
      await clearAuthEverywhere();
    }
  }

  /// Persist current auth session (token only – robust)
  Future<void> persistAuth() async {
    if (pb.authStore.isValid && pb.authStore.token.isNotEmpty) {
      await _storage.write(key: 'pb_token', value: pb.authStore.token);
    }
  }

  Future<void> clearAuthEverywhere() async {
    pb.authStore.clear();
    await _storage.delete(key: 'pb_token');
  }
}
