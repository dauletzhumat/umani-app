class InstallmentNextPayment {
  const InstallmentNextPayment({required this.dueDate, required this.amount});

  final String dueDate;
  final String amount;

  factory InstallmentNextPayment.fromJson(Map<String, dynamic> json) {
    return InstallmentNextPayment(
      dueDate: json['dueDate'] as String,
      amount: json['amount'] as String,
    );
  }
}

class Installment {
  const Installment({
    required this.id,
    required this.merchant,
    required this.totalAmount,
    required this.installmentsCount,
    required this.provider,
    required this.nextPayment,
  });

  final String id;
  final String merchant;
  final String totalAmount;
  final int installmentsCount;
  final String? provider;
  final InstallmentNextPayment? nextPayment;

  factory Installment.fromJson(Map<String, dynamic> json) {
    return Installment(
      id: json['id'] as String,
      merchant: json['merchant'] as String,
      totalAmount: json['totalAmount'] as String,
      installmentsCount: json['installmentsCount'] as int,
      provider: json['provider'] as String?,
      nextPayment:
          json['nextPayment'] == null
              ? null
              : InstallmentNextPayment.fromJson(
                json['nextPayment'] as Map<String, dynamic>,
              ),
    );
  }
}

/// GET /installments (docs/08_API.md §13) — totalOutstanding is a
/// server-computed aggregate, not a per-item field, so it's carried on
/// the overview rather than duplicated onto each Installment.
class InstallmentsOverview {
  const InstallmentsOverview({
    required this.totalOutstanding,
    required this.installments,
  });

  final String totalOutstanding;
  final List<Installment> installments;

  factory InstallmentsOverview.fromJson(Map<String, dynamic> json) {
    return InstallmentsOverview(
      totalOutstanding: json['totalOutstanding'] as String,
      installments:
          (json['installments'] as List<dynamic>)
              .map((item) => Installment.fromJson(item as Map<String, dynamic>))
              .toList(),
    );
  }
}
