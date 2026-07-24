import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../wallet/data/repositories/account_repository_impl.dart';
import '../../../wallet/domain/entities/account.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/widgets/category_picker_sheet.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/entities/transaction.dart';

/// Manual transaction entry (docs/04_User_Flows.md §6, Экран 6.1), shown
/// as a Bottom Sheet — the task's own test-plan calls it "шит" (sheet),
/// same presentation as AddAccountSheet/CategoryPickerSheet. Saving pops
/// the sheet and shows "Транзакция сохранена" (§6.4's exact toast copy)
/// rather than navigating to a confirmation screen or Dashboard, since
/// neither exists yet.
class ManualEntryScreen extends ConsumerStatefulWidget {
  const ManualEntryScreen({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => const FractionallySizedBox(
            heightFactor: 0.9,
            child: ManualEntryScreen(),
          ),
    );
  }

  @override
  ConsumerState<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends ConsumerState<ManualEntryScreen> {
  TransactionType _type = TransactionType.expense;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  Category? _selectedCategory;
  Account? _selectedAccount;
  DateTime _occurredAt = DateTime.now();
  bool _isSaving = false;

  bool get _hasPositiveAmount {
    final value = double.tryParse(_amountController.text.trim());
    return value != null && value > 0;
  }

  bool get _canSave =>
      _hasPositiveAmount && _selectedAccount != null && !_isSaving;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _selectDefaultAccount(List<Account> accounts) {
    if (_selectedAccount != null || accounts.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _selectedAccount = accounts.first);
    });
  }

  Future<void> _pickCategory() async {
    final category = await CategoryPickerSheet.show(context);
    if (category != null && mounted) {
      setState(() => _selectedCategory = category);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _occurredAt = picked);
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final account = _selectedAccount!;
    setState(() => _isSaving = true);

    await ref
        .read(transactionRepositoryProvider)
        .create(
          accountId: account.id,
          categoryId: _selectedCategory?.id,
          amount: _amountController.text.trim(),
          currency: account.currency,
          type: _type,
          occurredAt: _occurredAt.toIso8601String().split('T').first,
          note:
              _noteController.text.trim().isEmpty
                  ? null
                  : _noteController.text.trim(),
        );

    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.transactionSavedToast)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accountsAsync = ref.watch(accountListProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.manualEntryTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              SegmentedButton<TransactionType>(
                segments: [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text(l10n.manualEntryTypeExpense),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text(l10n.manualEntryTypeIncome),
                  ),
                ],
                selected: {_type},
                onSelectionChanged:
                    (selection) => setState(() => _type = selection.first),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.manualEntryAmountLabel,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.manualEntryCategoryLabel),
                subtitle: Text(
                  _selectedCategory?.name ?? l10n.manualEntryCategoryPlaceholder,
                ),
                leading:
                    _selectedCategory != null
                        ? Icon(_selectedCategory!.iconData)
                        : const Icon(Icons.category_outlined),
                onTap: _pickCategory,
              ),
              accountsAsync.when(
                data: (accounts) {
                  _selectDefaultAccount(accounts);
                  return DropdownButtonFormField<Account>(
                    initialValue: _selectedAccount,
                    decoration: InputDecoration(
                      labelText: l10n.manualEntryAccountLabel,
                    ),
                    items:
                        accounts
                            .map(
                              (account) => DropdownMenuItem(
                                value: account,
                                child: Text(account.name),
                              ),
                            )
                            .toList(),
                    onChanged:
                        (account) => setState(() => _selectedAccount = account),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text(l10n.errorNetwork),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.manualEntryDateLabel),
                subtitle: Text(
                  '${_occurredAt.year}-${_occurredAt.month.toString().padLeft(2, '0')}-${_occurredAt.day.toString().padLeft(2, '0')}',
                ),
                leading: const Icon(Icons.calendar_today_outlined),
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: l10n.manualEntryNoteLabel,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _canSave ? _save : null,
                child:
                    _isSaving
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Text(l10n.manualEntrySaveButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
