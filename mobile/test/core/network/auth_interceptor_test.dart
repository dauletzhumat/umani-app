import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/auth_interceptor.dart';
import 'package:mobile/core/network/token_manager.dart';
import 'package:mobile/core/storage/session_storage.dart';

class _FakeSessionStorage implements SessionStorage {
  String currentToken = 'old-refresh-token';
  final List<String> savedTokens = [];

  @override
  Future<String?> readRefreshToken() async => currentToken;

  @override
  Future<bool> hasSession() async => true;

  @override
  Future<void> saveRefreshToken(String token) async {
    currentToken = token;
    savedTokens.add(token);
  }

  @override
  Future<void> clear() async {}
}

/// Fakes the wire without a real HTTP stack. /protected returns 401 until
/// a refresh has completed, then 200 — models "the token was stale" rather
/// than "the Nth call fails", so it stays correct however many requests
/// are in flight when the token expires. A small delay on both endpoints
/// makes concurrent requests in the second test genuinely overlap instead
/// of resolving one at a time.
class _FakeAdapter implements HttpClientAdapter {
  int protectedCallCount = 0;
  int refreshCallCount = 0;
  bool _refreshed = false;

  static const _jsonHeaders = {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  };

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 5));

    if (options.path == '/protected') {
      protectedCallCount++;
      if (!_refreshed) {
        return ResponseBody.fromString(
          '{"error":{"code":"TOKEN_EXPIRED","message":"Access token has expired","traceId":"t"}}',
          401,
          headers: _jsonHeaders,
        );
      }
      return ResponseBody.fromString(
        '{"data":{"ok":true}}',
        200,
        headers: _jsonHeaders,
      );
    }

    if (options.path == '/auth/refresh') {
      refreshCallCount++;
      _refreshed = true;
      return ResponseBody.fromString(
        '{"data":{"accessToken":"new-access-$refreshCallCount","refreshToken":"new-refresh-$refreshCallCount","expiresIn":900}}',
        200,
        headers: _jsonHeaders,
      );
    }

    throw StateError('Unexpected request path in test: ${options.path}');
  }
}

({Dio dio, _FakeAdapter adapter, _FakeSessionStorage sessionStorage})
_buildClient() {
  final adapter = _FakeAdapter();
  final sessionStorage = _FakeSessionStorage();
  String? accessToken = 'expired-access-token';

  final refreshDio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = adapter;

  final tokenManager = TokenManager(
    refreshDio: refreshDio,
    sessionStorage: sessionStorage,
    getAccessToken: () => accessToken,
    setAccessToken: (token) => accessToken = token,
    clearAccessToken: () => accessToken = null,
  );

  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = adapter;
  dio.interceptors.add(AuthInterceptor(dio, tokenManager));

  return (dio: dio, adapter: adapter, sessionStorage: sessionStorage);
}

void main() {
  test(
    'on 401, refreshes via /auth/refresh and retries the original request exactly once',
    () async {
      final client = _buildClient();

      final response = await client.dio.get<Map<String, dynamic>>(
        '/protected',
      );

      expect(response.statusCode, 200);
      expect(response.data!['data'], {'ok': true});

      // Refreshed exactly once, and the original request was attempted
      // exactly twice total (the initial 401 + one retry) — not looping.
      expect(client.adapter.refreshCallCount, 1);
      expect(client.adapter.protectedCallCount, 2);
      expect(client.sessionStorage.savedTokens, ['new-refresh-1']);
    },
  );

  test(
    'concurrent 401s share a single in-flight refresh instead of each triggering one',
    () async {
      final client = _buildClient();

      final responses = await Future.wait([
        client.dio.get<Map<String, dynamic>>('/protected'),
        client.dio.get<Map<String, dynamic>>('/protected'),
        client.dio.get<Map<String, dynamic>>('/protected'),
      ]);

      expect(responses.every((r) => r.statusCode == 200), isTrue);
      // Not 3 — all three 401s awaited the same in-flight refresh.
      expect(client.adapter.refreshCallCount, 1);
    },
  );
}
