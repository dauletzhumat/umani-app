import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../budgets/data/repositories/budget_repository_impl.dart';
import '../../../installments/data/repositories/installment_repository_impl.dart';
import '../widgets/balance_widget.dart';
import '../widgets/recent_transactions_widget.dart';
import '../widgets/upcoming_installment_widget.dart';
import '../widgets/budgets_preview_widget.dart';

/// Dashboard layout (T8.1-T8.3, docs/05_UX.md §4): the period-balance
/// widget, the nearest installment payment (hidden if none), a preview
/// of the hottest budgets, and recent operations. Dashboard has no API
/// endpoints of its own — it only composes calls the wallet/budgets/
/// installments/transactions features already expose
/// (docs/MVP_Spec.md §10). Pull-to-refresh re-fetches all four sources
/// at once (T8.3's own test-plan).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _refreshAll(WidgetRef ref) {
    return Future.wait([
      ref.refresh(dashboardMonthlySpendingProvider.future),
      ref.refresh(recentTransactionsProvider.future),
      ref.refresh(budgetListProvider.future),
      ref.refresh(installmentsOverviewProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dashboardTitle)),
      body: RefreshIndicator(
        onRefresh: () => _refreshAll(ref),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BalanceWidget(),
              SizedBox(height: 16),
              UpcomingInstallmentWidget(),
              SizedBox(height: 16),
              BudgetsPreviewWidget(),
              SizedBox(height: 16),
              RecentTransactionsWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
