import '../entities/account.dart';

abstract class AccountRepository {
  /// GET /accounts — the caller's own, non-deleted accounts.
  Future<List<Account>> fetchAll();

  /// POST /accounts — creates an account starting at zero balance.
  Future<Account> create({
    required AccountType type,
    required String name,
    required String currency,
  });

  /// PATCH /accounts/{id} — rename/archive only (docs/08_API.md §8).
  Future<Account> update(String id, {String? name, bool? archived});
}
