import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Presence check + basic read/write for now. Full auto-refresh handling
/// (silently rotating the token on 401, wiring it into every request) is
/// T1.11's job; it reuses this same storage key.
class SessionStorage {
  static const refreshTokenKey = 'refresh_token';

  final _storage = const FlutterSecureStorage();

  Future<bool> hasSession() async {
    final token = await _storage.read(key: refreshTokenKey);
    return token != null;
  }

  Future<void> saveRefreshToken(String token) {
    return _storage.write(key: refreshTokenKey, value: token);
  }

  Future<void> clear() {
    return _storage.delete(key: refreshTokenKey);
  }
}
