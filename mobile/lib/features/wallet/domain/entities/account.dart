import 'package:flutter/material.dart';

/// Mirrors backend/src/modules/accounts/domain/entities/account.entity.ts's
/// `type` column (docs/07_Database.md §5.5's `account_type` enum).
enum AccountType { cash, bank, card, multiCurrency }

AccountType accountTypeFromString(String value) {
  switch (value) {
    case 'cash':
      return AccountType.cash;
    case 'bank':
      return AccountType.bank;
    case 'card':
      return AccountType.card;
    case 'multi_currency':
      return AccountType.multiCurrency;
    default:
      throw ArgumentError('Unknown account type: $value');
  }
}

String accountTypeToString(AccountType type) {
  switch (type) {
    case AccountType.cash:
      return 'cash';
    case AccountType.bank:
      return 'bank';
    case AccountType.card:
      return 'card';
    case AccountType.multiCurrency:
      return 'multi_currency';
  }
}

IconData accountTypeIcon(AccountType type) {
  switch (type) {
    case AccountType.cash:
      return Icons.payments;
    case AccountType.bank:
      return Icons.account_balance;
    case AccountType.card:
      return Icons.credit_card;
    case AccountType.multiCurrency:
      return Icons.public;
  }
}

class Account {
  const Account({
    required this.id,
    required this.userId,
    required this.type,
    required this.name,
    required this.currency,
    required this.balanceCached,
    required this.provider,
    required this.archived,
  });

  final String id;
  final String userId;
  final AccountType type;
  final String name;
  final String currency;
  final String balanceCached;
  final String? provider;
  final bool archived;

  IconData get iconData => accountTypeIcon(type);

  Account copyWith({String? name, bool? archived}) {
    return Account(
      id: id,
      userId: userId,
      type: type,
      name: name ?? this.name,
      currency: currency,
      balanceCached: balanceCached,
      provider: provider,
      archived: archived ?? this.archived,
    );
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: accountTypeFromString(json['type'] as String),
      name: json['name'] as String,
      currency: json['currency'] as String,
      balanceCached: json['balanceCached'] as String,
      provider: json['provider'] as String?,
      archived: json['archived'] as bool,
    );
  }
}
