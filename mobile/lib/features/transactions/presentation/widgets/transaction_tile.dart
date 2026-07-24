import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/widgets/category_picker_sheet.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/entities/transaction.dart';

/// A single row in the transaction feed (docs/04_User_Flows.md §5,
/// docs/05_UX.md §5's swipe actions). Swipe-right opens the category
/// picker inline (a Bottom Sheet, no navigation) to quickly recategorize
/// without leaving the list; swipe-left asks for delete confirmation.
/// [category] is resolved by the parent screen from [categoryListProvider]
/// data since a [Transaction] only carries a `categoryId`.
class TransactionTile extends ConsumerWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.category,
    required this.onCategoryChanged,
    required this.onDeleted,
  });

  final Transaction transaction;
  final Category? category;
  final ValueChanged<Category> onCategoryChanged;
  final VoidCallback onDeleted;

  Future<bool> _confirmDismiss(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    DismissDirection direction,
  ) async {
    if (direction == DismissDirection.startToEnd) {
      final newCategory = await CategoryPickerSheet.show(context);
      if (newCategory != null) {
        await ref
            .read(transactionRepositoryProvider)
            .update(transaction.id, categoryId: newCategory.id);
        onCategoryChanged(newCategory);
      }
      return false;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.transactionListDeleteConfirmTitle),
            content: Text(l10n.transactionListDeleteConfirmMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.transactionListDeleteCancelButton),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.transactionListDeleteConfirmButton),
              ),
            ],
          ),
    );
    if (confirmed != true) return false;

    await ref.read(transactionRepositoryProvider).delete(transaction.id);
    onDeleted();
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isExpense = transaction.type == TransactionType.expense;

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.horizontal,
      confirmDismiss:
          (direction) => _confirmDismiss(context, ref, l10n, direction),
      background: Container(
        color: Theme.of(context).colorScheme.secondaryContainer,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Icon(Icons.sync_alt),
      ),
      secondaryBackground: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Icon(Icons.delete_outline),
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(category?.iconData ?? Icons.category_outlined),
        ),
        title: Text(category?.name ?? l10n.transactionTileNoCategory),
        subtitle: Text(transaction.occurredAt),
        trailing: Text(
          '${isExpense ? '-' : '+'}${transaction.amount} ${transaction.currency}',
          style: TextStyle(
            color:
                isExpense
                    ? Theme.of(context).colorScheme.error
                    : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
