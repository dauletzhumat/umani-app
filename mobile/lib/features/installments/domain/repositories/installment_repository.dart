import '../entities/installment.dart';

abstract class InstallmentRepository {
  /// GET /installments — the map of all active installments plus the
  /// summed debt load, computed server-side (docs/08_API.md §13).
  Future<InstallmentsOverview> fetchAll();

  /// POST /installments — generates the payment schedule server-side
  /// (T7.2). The response has no nextPayment (that's GET's shape); the
  /// caller refetches the overview afterward to pick it up.
  Future<Installment> create({
    required String merchant,
    required String totalAmount,
    required int installmentsCount,
    required String startDate,
  });
}
