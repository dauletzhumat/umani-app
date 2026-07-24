import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

/// Raw HTTP calls to /transactions (docs/08_API.md §10) folded directly
/// into the repository — no separate datasource file, same self-contained
/// style as CategoryRepositoryImpl (T2.3)/AccountRepositoryImpl (T3.2).
class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Transaction> create({
    required String accountId,
    String? categoryId,
    required String amount,
    required String currency,
    required TransactionType type,
    String? occurredAt,
    String? note,
    String? source,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/transactions',
        data: {
          'accountId': accountId,
          'categoryId': ?categoryId,
          'amount': amount,
          'currency': currency,
          'type': transactionTypeToString(type),
          'occurredAt': ?occurredAt,
          'note': ?note,
          'source': ?source,
        },
      );
      return Transaction.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<TransactionPage> fetchAll({
    String? accountId,
    String? categoryId,
    TransactionType? type,
    String? dateFrom,
    String? dateTo,
    String? cursor,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/transactions',
        queryParameters: {
          'accountId': ?accountId,
          'categoryId': ?categoryId,
          'type': ?(type == null ? null : transactionTypeToString(type)),
          'dateFrom': ?dateFrom,
          'dateTo': ?dateTo,
          'cursor': ?cursor,
        },
      );
      final body = response.data!;
      final items =
          (body['data'] as List<dynamic>)
              .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
              .toList();
      final meta = body['meta'] as Map<String, dynamic>;
      return TransactionPage(
        items: items,
        nextCursor: meta['nextCursor'] as String?,
        hasMore: meta['hasMore'] as bool,
      );
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<Transaction> update(String id, {String? categoryId}) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/transactions/$id',
        data: {'categoryId': ?categoryId},
      );
      return Transaction.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete<void>('/transactions/$id');
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }
}

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryImpl(ref.watch(apiClientProvider));
});
