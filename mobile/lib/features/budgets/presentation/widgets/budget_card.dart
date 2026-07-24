import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/budget.dart';

/// A single budget's progress (T6.3, docs/05_UX.md). Color coding per the
/// task's own thresholds: green <70%, yellow 70–99%, red >=100%.
class BudgetCard extends StatelessWidget {
  const BudgetCard({super.key, required this.budget});

  final Budget budget;

  Color _indicatorColor(BuildContext context) {
    if (budget.progressPercent >= 100) return Colors.red;
    if (budget.progressPercent >= 70) return Colors.amber;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = _indicatorColor(context);
    final fraction = (budget.progressPercent / 100).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              budget.categoryName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 8,
                color: color,
                backgroundColor: color.withValues(alpha: 0.15),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.budgetCardProgress(budget.spentAmount, budget.amountLimit),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
