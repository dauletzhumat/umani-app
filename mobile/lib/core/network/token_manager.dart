// Named constructor params stay public (not `this._field`) so TokenManager
// is constructible with fakes from test files outside this library, while
// the backing fields stay private — that's what triggers this lint below.
// ignore_for_file: prefer_initializing_formals

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/access_token_provider.dart';
import '../storage/session_storage.dart';
import 'api_client.dart';

/// Access token: in memory only (AccessTokenNotifier, read/written via the
/// injected callbacks below — kept decoupled from Riverpod's Ref so this
/// class is trivially unit-testable with plain closures). Refresh token:
/// secure storage (SessionStorage). Owns the actual POST /auth/refresh
/// call (docs/08_API.md §2) — AuthInterceptor calls into this on 401.
///
/// Uses its own interceptor-free Dio for the refresh call itself —
/// reusing the main apiClientProvider's Dio here would create a circular
/// provider dependency (apiClientProvider needs this to build its
/// AuthInterceptor) and risks the refresh call recursing through its own
/// 401 handling if the refresh token itself is rejected.
class TokenManager {
  TokenManager({
    required Dio refreshDio,
    required SessionStorage sessionStorage,
    required String? Function() getAccessToken,
    required void Function(String token) setAccessToken,
    required void Function() clearAccessToken,
  }) : _refreshDio = refreshDio,
       _sessionStorage = sessionStorage,
       _getAccessToken = getAccessToken,
       _setAccessToken = setAccessToken,
       _clearAccessToken = clearAccessToken;

  final Dio _refreshDio;
  final SessionStorage _sessionStorage;
  final String? Function() _getAccessToken;
  final void Function(String token) _setAccessToken;
  final void Function() _clearAccessToken;

  String? get accessToken => _getAccessToken();

  Future<String> refreshAccessToken() async {
    final refreshToken = await _sessionStorage.readRefreshToken();
    if (refreshToken == null) {
      throw StateError('No refresh token available to refresh with');
    }

    final response = await _refreshDio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    final newAccessToken = data['accessToken'] as String;
    final newRefreshToken = data['refreshToken'] as String;

    await _sessionStorage.saveRefreshToken(newRefreshToken);
    _setAccessToken(newAccessToken);

    return newAccessToken;
  }

  Future<void> clear() async {
    await _sessionStorage.clear();
    _clearAccessToken();
  }
}

final tokenManagerProvider = Provider<TokenManager>((ref) {
  return TokenManager(
    refreshDio: Dio(BaseOptions(baseUrl: apiBaseUrl)),
    sessionStorage: SessionStorage(),
    getAccessToken: () => ref.read(accessTokenProvider),
    setAccessToken: (token) => ref.read(accessTokenProvider.notifier).set(token),
    clearAccessToken: () => ref.read(accessTokenProvider.notifier).clear(),
  );
});
