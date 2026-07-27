import '../entities/report.dart';

abstract class ReportsRepository {
  /// GET /reports/by-category?period=... (docs/08_API.md §23).
  Future<ByCategoryReport> fetchByCategory({required String period});

  /// GET /reports/summary?period=... (docs/08_API.md §23).
  Future<ReportsSummary> fetchSummary({required String period});
}
