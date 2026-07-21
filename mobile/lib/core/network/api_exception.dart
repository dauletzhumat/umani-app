import 'package:dio/dio.dart';

/// Parses the backend's error envelope (docs/08_API.md §3):
/// { "error": { "code", "message", "details", "traceId" } }.
class ApiException implements Exception {
  const ApiException({required this.code, required this.message});

  final String code;
  final String message;

  factory ApiException.fromDioException(DioException exception) {
    final data = exception.response?.data;
    if (data is Map && data['error'] is Map) {
      final error = data['error'] as Map;
      return ApiException(
        code: error['code'] as String? ?? 'UNKNOWN',
        message:
            error['message'] as String? ??
            exception.message ??
            'Unknown error',
      );
    }
    return ApiException(
      code: 'NETWORK_ERROR',
      message: exception.message ?? 'Network error',
    );
  }

  @override
  String toString() => 'ApiException($code: $message)';
}
