import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/account_repository.dart';

/// Raw HTTP calls to /accounts (docs/08_API.md §8) folded directly into
/// the repository — no separate datasource file, same self-contained
/// style as CategoryRepositoryImpl (T2.3).
class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<Account>> fetchAll() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/accounts');
      final data = response.data!['data'] as List<dynamic>;
      return data
          .map((json) => Account.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<Account> create({
    required AccountType type,
    required String name,
    required String currency,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/accounts',
        data: {
          'type': accountTypeToString(type),
          'name': name,
          'currency': currency,
        },
      );
      return Account.fromJson(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<Account> update(String id, {String? name, bool? archived}) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/accounts/$id',
        data: {'name': ?name, 'archived': ?archived},
      );
      return Account.fromJson(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }
}

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepositoryImpl(ref.watch(apiClientProvider));
});

final accountListProvider = FutureProvider<List<Account>>((ref) {
  return ref.watch(accountRepositoryProvider).fetchAll();
});
