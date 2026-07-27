import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/report.dart';
import '../../domain/repositories/reports_repository.dart';

/// Raw HTTP calls to /reports (docs/08_API.md §23) folded directly into
/// the repository — no separate datasource file, same self-contained
/// style as CategoryRepositoryImpl (T2.3)/AccountRepositoryImpl (T3.2).
class ReportsRepositoryImpl implements ReportsRepository {
  ReportsRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<ByCategoryReport> fetchByCategory({required String period}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/reports/by-category',
        queryParameters: {'period': period},
      );
      return ByCategoryReport.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<ReportsSummary> fetchSummary({required String period}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/reports/summary',
        queryParameters: {'period': period},
      );
      return ReportsSummary.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }
}

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepositoryImpl(ref.watch(apiClientProvider));
});

/// Family keyed by period ('week'/'month'/'year') so switching periods
/// caches each one independently (docs/MVP_Spec.md §11: "смена периода
/// пересчитывает диаграмму без лишних запросов").
final byCategoryReportProvider = FutureProvider.family<ByCategoryReport, String>(
  (ref, period) => ref.watch(reportsRepositoryProvider).fetchByCategory(period: period),
);

final reportsSummaryProvider = FutureProvider.family<ReportsSummary, String>(
  (ref, period) => ref.watch(reportsRepositoryProvider).fetchSummary(period: period),
);
