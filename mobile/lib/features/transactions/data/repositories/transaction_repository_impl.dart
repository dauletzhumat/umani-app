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
        },
      );
      return Transaction.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }
}

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryImpl(ref.watch(apiClientProvider));
});
