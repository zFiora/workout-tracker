import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pocketbase/pocketbase.dart';

class PB {
  PB._();
  static final PB I = PB._();

  
  static const String baseUrl = "http://10.0.2.2:8090";

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  
  late final PocketBase pb = PocketBase(baseUrl);

  
  Future<void> bootstrapAuth() async {
    final token = await _storage.read(key: 'pb_token');
    if (token == null) return;

    
    pb.authStore.save(token, null);
    try {
      await pb.collection('users').authRefresh();
    } catch (_) {
      await clearAuthEverywhere();
    }
  }

  
  Future<void> persistAuth() async {
    if (pb.authStore.isValid && pb.authStore.token.isNotEmpty) {
      // keep store in sync
      pb.authStore.save(pb.authStore.token, pb.authStore.record);
      await _storage.write(key: 'pb_token', value: pb.authStore.token);
    }
  }

  Future<void> clearAuthEverywhere() async {
    pb.authStore.clear();
    await _storage.delete(key: 'pb_token');
  }
}
