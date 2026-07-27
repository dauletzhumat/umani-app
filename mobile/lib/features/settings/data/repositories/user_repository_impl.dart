import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';

/// Raw HTTP calls to /users/me folded directly into the repository — same
/// self-contained style as ReportsRepositoryImpl (T9.2).
class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<UserProfile> fetchProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/users/me');
      return UserProfile.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<UserProfile> updateProfile({
    String? name,
    String? defaultCurrency,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/users/me',
        data: {
          'name': ?name,
          'defaultCurrency': ?defaultCurrency,
        },
      );
      return UserProfile.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<String> deleteAccount() async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>('/users/me');
      final data = response.data!['data'] as Map<String, dynamic>;
      return data['scheduledPurgeAt'] as String;
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(ref.watch(apiClientProvider));
});

final userProfileProvider = FutureProvider<UserProfile>((ref) {
  return ref.watch(userRepositoryProvider).fetchProfile();
});
