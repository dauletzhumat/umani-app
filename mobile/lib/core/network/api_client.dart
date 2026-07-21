import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Host is a placeholder for local dev — per-environment config
/// (dev/staging/prod, Android emulator's 10.0.2.2 vs iOS localhost etc.)
/// lands with the token/auth wiring in T1.11. The /api/v1 prefix itself
/// matches the real backend (docs/08_API.md §0) and is needed now, T1.9
/// is the first task that actually calls it.
const _baseUrl = 'http://localhost:3000/api/v1';

final apiClientProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(baseUrl: _baseUrl));
});
