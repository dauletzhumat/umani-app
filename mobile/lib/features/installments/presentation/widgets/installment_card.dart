import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/installment.dart';

/// A single installment plan (T7.4, docs/04_User_Flows.md §8): merchant,
/// how many payments make up the plan, and its own next payment — this
/// per-card "next payment" is the calendar's stand-in, since GET
/// /installments doesn't return a month-wide payment calendar.
class InstallmentCard extends StatelessWidget {
  const InstallmentCard({super.key, required this.installment});

  final Installment installment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final nextPayment = installment.nextPayment;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              installment.merchant,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (installment.provider != null) ...[
              const SizedBox(height: 2),
              Text(
                installment.provider!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '${installment.totalAmount} · '
              '${l10n.installmentCardInstallmentsCount(installment.installmentsCount)}',
            ),
            const SizedBox(height: 4),
            Text(
              nextPayment != null
                  ? l10n.installmentCardNextPayment(
                    nextPayment.amount,
                    nextPayment.dueDate,
                  )
                  : l10n.installmentCardNoNextPayment,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
