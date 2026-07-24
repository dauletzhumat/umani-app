enum BudgetPeriod { weekly, monthly }

BudgetPeriod budgetPeriodFromString(String value) {
  switch (value) {
    case 'weekly':
      return BudgetPeriod.weekly;
    case 'monthly':
      return BudgetPeriod.monthly;
    default:
      throw ArgumentError('Unknown budget period: $value');
  }
}

String budgetPeriodToString(BudgetPeriod period) {
  switch (period) {
    case BudgetPeriod.weekly:
      return 'weekly';
    case BudgetPeriod.monthly:
      return 'monthly';
  }
}

/// spentAmount/remainingAmount/progressPercent are never stored server
/// side — always computed live from transactions (docs/08_API.md §11).
class Budget {
  const Budget({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.amountLimit,
    required this.period,
    required this.startDate,
    required this.spentAmount,
    required this.remainingAmount,
    required this.progressPercent,
  });

  final String id;
  final String categoryId;
  final String categoryName;
  final String amountLimit;
  final BudgetPeriod period;
  final String startDate;
  final String spentAmount;
  final String remainingAmount;
  final int progressPercent;

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      amountLimit: json['amountLimit'] as String,
      period: budgetPeriodFromString(json['period'] as String),
      startDate: json['startDate'] as String,
      spentAmount: json['spentAmount'] as String,
      remainingAmount: json['remainingAmount'] as String,
      progressPercent: json['progressPercent'] as int,
    );
  }
}
