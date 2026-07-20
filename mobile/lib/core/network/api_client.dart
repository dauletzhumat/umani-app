import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Base URL placeholder — real per-environment config (dev/staging/prod)
/// lands with the token/auth wiring in T1.11.
const _baseUrl = 'http://localhost:3000';

final apiClientProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(baseUrl: _baseUrl));
});
