import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../budgets/data/repositories/budget_repository_impl.dart';
import '../../../budgets/presentation/widgets/budget_card.dart';
import '../../../budgets/presentation/widgets/create_budget_sheet.dart';
import 'dashboard_empty_state.dart';
import 'dashboard_skeleton.dart';

/// Preview of the 2-3 "hottest" budgets (docs/05_UX.md §4) — closest to
/// their limit, so the user sees what needs attention first. Reuses
/// BudgetCard (T6.3) as-is rather than duplicating its progress-bar/
/// color logic. Empty state replaces the preview with a CTA to create
/// the first budget (T8.3, same §4).
class BudgetsPreviewWidget extends ConsumerWidget {
  const BudgetsPreviewWidget({super.key});

  static const _maxPreviewCount = 3;

  Future<void> _createFirstBudget(BuildContext context, WidgetRef ref) async {
    final created = await CreateBudgetSheet.show(context);
    if (created != null) {
      ref.invalidate(budgetListProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final budgetsAsync = ref.watch(budgetListProvider);

    return budgetsAsync.when(
      data: (budgets) {
        if (budgets.isEmpty) {
          return DashboardEmptyState(
            message: l10n.dashboardEmptyBudgetsMessage,
            buttonLabel: l10n.dashboardEmptyBudgetsButton,
            onTap: () => _createFirstBudget(context, ref),
          );
        }

        final hottest = [...budgets]
          ..sort((a, b) => b.progressPercent.compareTo(a.progressPercent));
        final preview = hottest.take(_maxPreviewCount);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                l10n.budgetListTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            for (final budget in preview) BudgetCard(budget: budget),
          ],
        );
      },
      loading: () => const DashboardSkeleton(),
      // A dashboard preview shouldn't surface an error card of its own —
      // it just quietly omits itself, same as before.
      error: (error, _) => const SizedBox.shrink(),
    );
  }
}
