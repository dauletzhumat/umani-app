import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Reads/writes the refresh token — the one piece of session state that's
/// persisted (access token stays in-memory only, see AccessTokenNotifier).
class SessionStorage {
  static const refreshTokenKey = 'refresh_token';

  final _storage = const FlutterSecureStorage();

  Future<String?> readRefreshToken() {
    return _storage.read(key: refreshTokenKey);
  }

  Future<bool> hasSession() async {
    return (await readRefreshToken()) != null;
  }

  Future<void> saveRefreshToken(String token) {
    return _storage.write(key: refreshTokenKey, value: token);
  }

  Future<void> clear() {
    return _storage.delete(key: refreshTokenKey);
  }
}
