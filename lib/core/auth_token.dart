import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the JWT for the current session. Replaces PB.I / PocketBase auth.
class AuthToken {
  AuthToken._();
  static final AuthToken I = AuthToken._();

  final _storage = const FlutterSecureStorage();
  static const _key = 'jwt_token';

  String? _token;
  String? _userId;

  String? get token => _token;
  String? get userId => _userId;
  bool get isValid => _token != null && _token!.isNotEmpty;

  Future<void> save(String token, String userId) async {
    _token = token;
    _userId = userId;
    await _storage.write(key: _key, value: token);
  }

  /// Call once at app start (before runApp) to restore a persisted session.
  Future<void> load() async {
    _token = await _storage.read(key: _key);
    if (_token != null) _userId = _decodeUserId(_token!);
  }

  Future<void> clear() async {
    _token = null;
    _userId = null;
    await _storage.delete(key: _key);
  }

  String? _decodeUserId(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      return map['sub'] as String?;
    } catch (_) {
      return null;
    }
  }
}
