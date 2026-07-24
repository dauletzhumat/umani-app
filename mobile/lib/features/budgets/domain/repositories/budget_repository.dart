import '../entities/budget.dart';

abstract class BudgetRepository {
  /// GET /budgets — every budget owned by the caller, with progress
  /// computed server-side. Not paginated (docs/08_API.md §11).
  Future<List<Budget>> fetchAll();
}
