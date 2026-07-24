import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/repositories/budget_repository_impl.dart';
import '../widgets/budget_card.dart';
import '../widgets/create_budget_sheet.dart';

/// Budget list (T6.3, docs/05_UX.md): progress bars with color coding per
/// BudgetCard's thresholds. Not yet wired into app navigation — its
/// intended entry point, Dashboard (M8), doesn't exist yet.
class BudgetListScreen extends ConsumerWidget {
  const BudgetListScreen({super.key});

  Future<void> _openCreateBudgetSheet(BuildContext context, WidgetRef ref) async {
    final created = await CreateBudgetSheet.show(context);
    if (created != null) {
      ref.invalidate(budgetListProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final budgetsAsync = ref.watch(budgetListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.budgetListTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateBudgetSheet(context, ref),
        child: const Icon(Icons.add),
      ),
      body: budgetsAsync.when(
        data: (budgets) {
          if (budgets.isEmpty) {
            return Center(child: Text(l10n.budgetListEmptyMessage));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: budgets.length,
            itemBuilder:
                (context, index) => BudgetCard(budget: budgets[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(l10n.errorNetwork)),
      ),
    );
  }
}
