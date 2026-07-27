import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../widgets/balance_widget.dart';
import '../widgets/recent_transactions_widget.dart';

/// Dashboard layout (T8.1, docs/05_UX.md §4): the period-balance widget
/// plus a preview of recent operations. Dashboard has no API endpoints
/// of its own — it only composes calls the wallet/transactions features
/// already expose (docs/MVP_Spec.md §10). Budgets/installments widgets
/// land in T8.2; empty/skeleton/pull-to-refresh states in T8.3.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dashboardTitle)),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BalanceWidget(),
            SizedBox(height: 16),
            RecentTransactionsWidget(),
          ],
        ),
      ),
    );
  }
}
