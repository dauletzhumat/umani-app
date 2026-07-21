import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/account_repository_impl.dart';
import '../entities/account.dart';
import '../repositories/account_repository.dart';

class CreateAccount {
  CreateAccount(this._repository);

  final AccountRepository _repository;

  Future<Account> call({
    required AccountType type,
    required String name,
    required String currency,
  }) {
    return _repository.create(type: type, name: name, currency: currency);
  }
}

final createAccountProvider = Provider<CreateAccount>((ref) {
  return CreateAccount(ref.watch(accountRepositoryProvider));
});
