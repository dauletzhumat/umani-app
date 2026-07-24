import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../categories/data/repositories/category_repository_impl.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/widgets/category_picker_sheet.dart';
import '../../../wallet/data/repositories/account_repository_impl.dart';
import '../../../wallet/domain/entities/account.dart';
import '../../data/datasources/ocr_remote_datasource.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/entities/transaction.dart';

/// Editable preview of an OCR draft (docs/04_User_Flows.md §6, Экран 6.2:
/// "экран предпросмотра распознанных данных ... возможность вручную
/// поправить"). Confirming reuses T4.2/T4.7's existing POST /transactions
/// (via TransactionRepository) with source: 'ocr' — the backend's OCR
/// response is an embedded draft, not a created transaction row, and no
/// task builds a dedicated confirm endpoint for it (08_API.md §18).
class ReceiptPreviewScreen extends ConsumerStatefulWidget {
  const ReceiptPreviewScreen({super.key, required this.scanResult});

  final ReceiptScanResult scanResult;

  @override
  ConsumerState<ReceiptPreviewScreen> createState() =>
      _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends ConsumerState<ReceiptPreviewScreen> {
  late final TextEditingController _amountController;
  late final List<TextEditingController> _itemNameControllers;
  late final List<TextEditingController> _itemPriceControllers;
  Category? _selectedCategory;
  Account? _selectedAccount;
  bool _categoryDefaulted = false;
  bool _isSaving = false;

  DraftTransaction? get _draft => widget.scanResult.draftTransaction;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: _draft?.amount ?? '');
    final items = _draft?.lineItems ?? const [];
    _itemNameControllers =
        items.map((item) => TextEditingController(text: item.name)).toList();
    _itemPriceControllers =
        items
            .map((item) => TextEditingController(text: item.price))
            .toList();
  }

  @override
  void dispose() {
    _amountController.dispose();
    for (final controller in _itemNameControllers) {
      controller.dispose();
    }
    for (final controller in _itemPriceControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _canConfirm {
    final amount = double.tryParse(_amountController.text.trim());
    return amount != null && amount > 0 && _selectedAccount != null && !_isSaving;
  }

  void _defaultCategory(List<Category> categories) {
    if (_categoryDefaulted || _draft?.suggestedCategoryId == null) return;
    _categoryDefaulted = true;
    Category? match;
    for (final category in categories) {
      if (category.id == _draft!.suggestedCategoryId) {
        match = category;
        break;
      }
    }
    if (match != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedCategory = match);
      });
    }
  }

  void _defaultAccount(List<Account> accounts) {
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

  Future<void> _confirm() async {
    if (!_canConfirm) return;
    final account = _selectedAccount!;
    setState(() => _isSaving = true);

    await ref
        .read(transactionRepositoryProvider)
        .create(
          accountId: account.id,
          categoryId: _selectedCategory?.id,
          amount: _amountController.text.trim(),
          currency: account.currency,
          type: TransactionType.expense,
          note: _draft?.merchant,
          source: 'ocr',
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
    final categoriesAsync = ref.watch(categoryListProvider);
    final accountsAsync = ref.watch(accountListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.receiptPreviewTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_draft?.merchant != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _draft!.merchant!,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.manualEntryAmountLabel,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              categoriesAsync.when(
                data: (categories) {
                  _defaultCategory(categories);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.manualEntryCategoryLabel),
                    subtitle: Text(
                      _selectedCategory?.name ??
                          l10n.manualEntryCategoryPlaceholder,
                    ),
                    leading:
                        _selectedCategory != null
                            ? Icon(_selectedCategory!.iconData)
                            : const Icon(Icons.category_outlined),
                    onTap: _pickCategory,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text(l10n.errorNetwork),
              ),
              const SizedBox(height: 16),
              accountsAsync.when(
                data: (accounts) {
                  _defaultAccount(accounts);
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
              if (_itemNameControllers.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  l10n.receiptPreviewLineItemsLabel,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < _itemNameControllers.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _itemNameControllers[i],
                            decoration: InputDecoration(
                              labelText: l10n.receiptPreviewLineItemNameLabel,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _itemPriceControllers[i],
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: l10n.receiptPreviewLineItemPriceLabel,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _canConfirm ? _confirm : null,
                child:
                    _isSaving
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Text(l10n.receiptPreviewConfirmButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
