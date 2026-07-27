import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../transactions/data/repositories/transaction_repository_impl.dart';
import '../../../transactions/domain/entities/transaction.dart';

/// "Остаток бюджета периода" (docs/05_UX.md §4) needs a sum across all
/// the user's budgets — but this task (T8.1) only depends on T4.9/T3.2,
/// not M6 (budgets), which lands separately in T8.2's
/// budgets_preview_widget.dart. Until then, this shows current-month
/// spending instead of a limit/percentage, which also sidesteps the
/// "total account balance" anti-pattern 05_UX.md explicitly warns
/// against for this widget.
///
/// Sums a single page (limit: 100) rather than following cursors across
/// multiple requests — a reasonable simplification for a dashboard
/// summary; a user with >100 expense transactions in one month would
/// see an undercount.
final dashboardMonthlySpendingProvider = FutureProvider<String>((ref) async {
  final now = DateTime.now();
  final firstOfMonth =
      '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-01';

  final page = await ref
      .watch(transactionRepositoryProvider)
      .fetchAll(
        type: TransactionType.expense,
        dateFrom: firstOfMonth,
        limit: 100,
      );

  final total = page.items.fold<double>(
    0,
    (sum, transaction) => sum + double.parse(transaction.amount),
  );
  return total.toStringAsFixed(2);
});

class BalanceWidget extends ConsumerWidget {
  const BalanceWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final spendingAsync = ref.watch(dashboardMonthlySpendingProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.balanceWidgetMonthlySpendingLabel,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            spendingAsync.when(
              data:
                  (amount) =>
                      Text(amount, style: Theme.of(context).textTheme.headlineMedium),
              loading:
                  () => const SizedBox(
                    height: 32,
                    width: 32,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              error: (error, _) => Text(l10n.errorNetwork),
            ),
          ],
        ),
      ),
    );
  }
}
