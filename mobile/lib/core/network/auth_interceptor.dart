import 'package:dio/dio.dart';
import 'token_manager.dart';

/// Attaches the access token to every request and, on 401, refreshes once
/// and retries the original request exactly once. Concurrent 401s share a
/// single in-flight refresh (`_refreshFuture`) rather than each triggering
/// their own — the backend rotates refresh tokens on use (T1.4), so two
/// simultaneous refresh calls would have the second one replay an
/// already-consumed token and trip the backend's compromise detection,
/// revoking every session.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio, this._tokenManager);

  static const _retriedKey = 'auth_interceptor_retried';

  final Dio _dio;
  final TokenManager _tokenManager;
  Future<String>? _refreshFuture;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _tokenManager.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra[_retriedKey] == true;

    if (!isUnauthorized || alreadyRetried) {
      handler.next(err);
      return;
    }

    try {
      final newToken = await _refresh();

      final retriedOptions = err.requestOptions;
      retriedOptions.extra[_retriedKey] = true;
      retriedOptions.headers['Authorization'] = 'Bearer $newToken';

      final response = await _dio.fetch<dynamic>(retriedOptions);
      handler.resolve(response);
    } catch (_) {
      handler.next(err);
    }
  }

  Future<String> _refresh() {
    return _refreshFuture ??= _tokenManager.refreshAccessToken().whenComplete(
      () => _refreshFuture = null,
    );
  }
}
