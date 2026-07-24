import '../entities/budget.dart';

abstract class BudgetRepository {
  /// GET /budgets — every budget owned by the caller, with progress
  /// computed server-side. Not paginated (docs/08_API.md §11).
  Future<List<Budget>> fetchAll();

  /// POST /budgets — 409s if a budget already exists for this
  /// categoryId/period/startDate (uq_budgets_user_category_period, T6.1).
  Future<Budget> create({
    required String categoryId,
    required String amountLimit,
    required BudgetPeriod period,
    required String startDate,
  });
}
