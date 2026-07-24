import '../entities/transaction.dart';

class TransactionPage {
  const TransactionPage({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });

  final List<Transaction> items;
  final String? nextCursor;
  final bool hasMore;
}

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
    String? source,
  });

  /// GET /transactions — cursor-paginated, opaque cursor from the
  /// previous page's [TransactionPage.nextCursor] (docs/08_API.md §4).
  Future<TransactionPage> fetchAll({
    String? accountId,
    String? categoryId,
    TransactionType? type,
    String? dateFrom,
    String? dateTo,
    String? cursor,
  });

  /// PATCH /transactions/{id} — used for the swipe-right quick
  /// category-change action (docs/05_UX.md §5).
  Future<Transaction> update(String id, {String? categoryId});

  /// DELETE /transactions/{id} — swipe-left action (docs/05_UX.md §5).
  Future<void> delete(String id);
}
