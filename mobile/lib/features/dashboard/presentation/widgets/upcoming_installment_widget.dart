import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../installments/data/repositories/installment_repository_impl.dart';
import 'dashboard_skeleton.dart';

/// The single nearest upcoming payment across all active installments
/// (docs/05_UX.md §4) — entirely hidden when there isn't one (no
/// installments at all, or every installment is already fully paid
/// off, i.e. every nextPayment is null).
class UpcomingInstallmentWidget extends ConsumerWidget {
  const UpcomingInstallmentWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final overviewAsync = ref.watch(installmentsOverviewProvider);

    return overviewAsync.when(
      data: (overview) {
        final withNextPayment =
            overview.installments
                .where((installment) => installment.nextPayment != null)
                .toList()
              ..sort(
                (a, b) => a.nextPayment!.dueDate.compareTo(
                  b.nextPayment!.dueDate,
                ),
              );
        if (withNextPayment.isEmpty) return const SizedBox.shrink();

        final nearest = withNextPayment.first;
        final daysUntil = _daysUntil(nearest.nextPayment!.dueDate);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.upcomingInstallmentTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.upcomingInstallmentMerchantAmount(
                    nearest.merchant,
                    nearest.nextPayment!.amount,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.upcomingInstallmentInDays(daysUntil),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const DashboardSkeleton(height: 48),
      // Same as BudgetsPreviewWidget: a failed load just quietly omits
      // this widget rather than showing an error card on the dashboard.
      error: (error, _) => const SizedBox.shrink(),
    );
  }

  // Not clamped to >=0 — an overdue pending payment (past due_date, not
  // yet marked paid) would show a negative count, an edge case left
  // unrefined for MVP.
  int _daysUntil(String dueDate) {
    final due = DateTime.parse(dueDate);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return due.difference(today).inDays;
  }
}
