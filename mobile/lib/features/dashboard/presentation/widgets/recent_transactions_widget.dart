import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../categories/data/repositories/category_repository_impl.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../transactions/data/repositories/transaction_repository_impl.dart';
import '../../../transactions/domain/entities/transaction.dart';

/// Last 3-5 operations (docs/05_UX.md §4) — read-only preview, unlike
/// TransactionListScreen's swipeable feed; there's no "Все" link target
/// yet since Dashboard itself isn't wired into navigation (M8).
final recentTransactionsProvider = FutureProvider<List<Transaction>>((
  ref,
) async {
  final page = await ref
      .watch(transactionRepositoryProvider)
      .fetchAll(limit: 5);
  return page.items;
});

class RecentTransactionsWidget extends ConsumerWidget {
  const RecentTransactionsWidget({super.key});

  Category? _categoryById(List<Category> categories, String? id) {
    if (id == null) return null;
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final transactionsAsync = ref.watch(recentTransactionsProvider);
    final categories = ref.watch(categoryListProvider).value ?? const [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.recentTransactionsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            transactionsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return Text(l10n.recentTransactionsEmptyMessage);
                }
                return Column(
                  children: [
                    for (final transaction in items)
                      _TransactionRow(
                        transaction: transaction,
                        category: _categoryById(
                          categories,
                          transaction.categoryId,
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text(l10n.errorNetwork),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction, required this.category});

  final Transaction transaction;
  final Category? category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isExpense = transaction.type == TransactionType.expense;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        child: Icon(category?.iconData ?? Icons.category_outlined),
      ),
      title: Text(category?.name ?? l10n.transactionTileNoCategory),
      subtitle: Text(transaction.occurredAt),
      trailing: Text(
        '${isExpense ? '-' : '+'}${transaction.amount} ${transaction.currency}',
        style: TextStyle(
          color: isExpense ? Theme.of(context).colorScheme.error : Colors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
