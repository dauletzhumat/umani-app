import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/installment.dart';
import '../../domain/repositories/installment_repository.dart';

/// Raw HTTP calls to /installments (docs/08_API.md §13) folded directly
/// into the repository — no separate datasource file, same self-contained
/// style as CategoryRepositoryImpl (T2.3)/AccountRepositoryImpl (T3.2).
class InstallmentRepositoryImpl implements InstallmentRepository {
  InstallmentRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<InstallmentsOverview> fetchAll() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/installments');
      return InstallmentsOverview.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }
}

final installmentRepositoryProvider = Provider<InstallmentRepository>((ref) {
  return InstallmentRepositoryImpl(ref.watch(apiClientProvider));
});

final installmentsOverviewProvider = FutureProvider<InstallmentsOverview>((
  ref,
) {
  return ref.watch(installmentRepositoryProvider).fetchAll();
});
