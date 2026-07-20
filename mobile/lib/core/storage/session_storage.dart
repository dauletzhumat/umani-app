import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Only a presence check for now — Splash needs to know whether *some*
/// session exists to branch on. Full token read/write/auto-refresh is
/// T1.11's job; it reuses this same storage key.
class SessionStorage {
  static const refreshTokenKey = 'refresh_token';

  final _storage = const FlutterSecureStorage();

  Future<bool> hasSession() async {
    final token = await _storage.read(key: refreshTokenKey);
    return token != null;
  }
}
