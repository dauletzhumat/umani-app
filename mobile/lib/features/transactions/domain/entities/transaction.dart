enum TransactionType { income, expense }

TransactionType transactionTypeFromString(String value) {
  switch (value) {
    case 'income':
      return TransactionType.income;
    case 'expense':
      return TransactionType.expense;
    default:
      throw ArgumentError('Unknown transaction type: $value');
  }
}

String transactionTypeToString(TransactionType type) {
  switch (type) {
    case TransactionType.income:
      return 'income';
    case TransactionType.expense:
      return 'expense';
  }
}

class Transaction {
  const Transaction({
    required this.id,
    required this.accountId,
    required this.categoryId,
    required this.amount,
    required this.currency,
    required this.type,
    required this.occurredAt,
    required this.note,
  });

  final String id;
  final String accountId;
  final String? categoryId;
  final String amount;
  final String currency;
  final TransactionType type;
  final String occurredAt;
  final String? note;

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      accountId: json['accountId'] as String,
      categoryId: json['categoryId'] as String?,
      amount: json['amount'] as String,
      currency: json['currency'] as String,
      type: transactionTypeFromString(json['type'] as String),
      occurredAt: json['occurredAt'] as String,
      note: json['note'] as String?,
    );
  }
}
