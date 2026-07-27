import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../budgets/data/repositories/budget_repository_impl.dart';
import '../../../budgets/presentation/widgets/budget_card.dart';

/// Preview of the 2-3 "hottest" budgets (docs/05_UX.md §4) — closest to
/// their limit, so the user sees what needs attention first. Reuses
/// BudgetCard (T6.3) as-is rather than duplicating its progress-bar/
/// color logic.
class BudgetsPreviewWidget extends ConsumerWidget {
  const BudgetsPreviewWidget({super.key});

  static const _maxPreviewCount = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final budgetsAsync = ref.watch(budgetListProvider);

    return budgetsAsync.when(
      data: (budgets) {
        if (budgets.isEmpty) return const SizedBox.shrink();

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
      loading: () => const Center(child: CircularProgressIndicator()),
      // A dashboard preview shouldn't surface an error card of its own —
      // it just quietly omits itself, same as the empty case.
      error: (error, _) => const SizedBox.shrink(),
    );
  }
}
