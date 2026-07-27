class CategoryBreakdown {
  const CategoryBreakdown({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.percentage,
  });

  final String? categoryId;
  final String categoryName;
  final String amount;
  final int percentage;

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdown(
      categoryId: json['categoryId'] as String?,
      categoryName: json['categoryName'] as String,
      amount: json['amount'] as String,
      percentage: json['percentage'] as int,
    );
  }
}

/// GET /reports/by-category (docs/08_API.md §23) — expense-only.
/// dateFrom/dateTo are the server-resolved period bounds (T9.1's
/// calendar-aligned windows) — carried through so the client can filter
/// the embedded transaction list by the exact same range, rather than
/// reimplementing the period math itself.
class ByCategoryReport {
  const ByCategoryReport({
    required this.dateFrom,
    required this.dateTo,
    required this.totalExpense,
    required this.categories,
  });

  final String dateFrom;
  final String dateTo;
  final String totalExpense;
  final List<CategoryBreakdown> categories;

  factory ByCategoryReport.fromJson(Map<String, dynamic> json) {
    return ByCategoryReport(
      dateFrom: json['dateFrom'] as String,
      dateTo: json['dateTo'] as String,
      totalExpense: json['totalExpense'] as String,
      categories:
          (json['categories'] as List<dynamic>)
              .map(
                (item) =>
                    CategoryBreakdown.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
    );
  }
}

/// GET /reports/summary (docs/08_API.md §23).
class ReportsSummary {
  const ReportsSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.previousPeriodTotalExpense,
  });

  final String totalIncome;
  final String totalExpense;
  final String previousPeriodTotalExpense;

  factory ReportsSummary.fromJson(Map<String, dynamic> json) {
    return ReportsSummary(
      totalIncome: json['totalIncome'] as String,
      totalExpense: json['totalExpense'] as String,
      previousPeriodTotalExpense: json['previousPeriodTotalExpense'] as String,
    );
  }
}
