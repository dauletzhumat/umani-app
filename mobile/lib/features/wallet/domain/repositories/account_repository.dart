import '../entities/account.dart';

abstract class AccountRepository {
  /// GET /accounts — the caller's own, non-deleted accounts.
  Future<List<Account>> fetchAll();

  /// PATCH /accounts/{id} — rename/archive only (docs/08_API.md §8).
  Future<Account> update(String id, {String? name, bool? archived});
}
