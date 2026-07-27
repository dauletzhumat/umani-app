import '../entities/installment.dart';

abstract class InstallmentRepository {
  /// GET /installments — the map of all active installments plus the
  /// summed debt load, computed server-side (docs/08_API.md §13).
  Future<InstallmentsOverview> fetchAll();
}
