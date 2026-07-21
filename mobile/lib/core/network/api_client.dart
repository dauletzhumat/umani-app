import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_interceptor.dart';
import 'token_manager.dart';

/// Host is a placeholder for local dev — real per-environment config
/// (dev/staging/prod, Android emulator's 10.0.2.2 vs iOS localhost etc.)
/// is a separate, later concern; not blocking for local development.
const apiBaseUrl = 'http://localhost:3000/api/v1';

final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(baseUrl: apiBaseUrl));
  dio.interceptors.add(AuthInterceptor(dio, ref.watch(tokenManagerProvider)));
  return dio;
});
