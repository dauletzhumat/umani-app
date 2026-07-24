import '../entities/transaction.dart';

abstract class TransactionRepository {
  /// POST /transactions — occurredAt defaults server-side to today when
  /// omitted (docs/08_API.md §10).
  Future<Transaction> create({
    required String accountId,
    String? categoryId,
    required String amount,
    required String currency,
    required TransactionType type,
    String? occurredAt,
    String? note,
  });
}
