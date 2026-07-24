import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';

/// Raw HTTP calls to /budgets (docs/08_API.md §11) folded directly into
/// the repository — no separate datasource file, same self-contained
/// style as CategoryRepositoryImpl (T2.3)/AccountRepositoryImpl (T3.2).
class BudgetRepositoryImpl implements BudgetRepository {
  BudgetRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<Budget>> fetchAll() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/budgets');
      final data = response.data!['data'] as List<dynamic>;
      return data
          .map((json) => Budget.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<Budget> create({
    required String categoryId,
    required String amountLimit,
    required BudgetPeriod period,
    required String startDate,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/budgets',
        data: {
          'categoryId': categoryId,
          'amountLimit': amountLimit,
          'period': budgetPeriodToString(period),
          'startDate': startDate,
        },
      );
      return Budget.fromJson(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }
}

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepositoryImpl(ref.watch(apiClientProvider));
});

final budgetListProvider = FutureProvider<List<Budget>>((ref) {
  return ref.watch(budgetRepositoryProvider).fetchAll();
});
