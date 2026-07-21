import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';

/// Raw HTTP calls to /auth/* (docs/08_API.md §2) — returns the unwrapped
/// `data` payload, no domain mapping here.
class AuthRemoteDatasource {
  AuthRemoteDatasource(this._dio);

  final Dio _dio;

  Future<void> register(String identifier) =>
      _post('/auth/register', {'identifier': identifier});

  Future<void> login(String identifier) =>
      _post('/auth/login', {'identifier': identifier});

  Future<Map<String, dynamic>> verifyOtp(String identifier, String code) =>
      _post('/auth/otp/verify', {'identifier': identifier, 'code': code});

  Future<Map<String, dynamic>> startGuestSession() =>
      _post('/auth/guest', const {});

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: body,
      );
      return response.data!['data'] as Map<String, dynamic>;
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }
}

final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  return AuthRemoteDatasource(ref.watch(apiClientProvider));
});
