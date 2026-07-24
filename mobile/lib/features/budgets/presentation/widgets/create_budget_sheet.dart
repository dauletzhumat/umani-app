import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_exception.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/widgets/category_picker_sheet.dart';
import '../../data/repositories/budget_repository_impl.dart';
import '../../domain/entities/budget.dart';

/// Bottom Sheet for creating a budget (T6.4, docs/Development_Tasks.md):
/// "выбора категории и лимита" — just those two inputs. Period/startDate
/// aren't exposed in the UI; every budget created here is a monthly
/// budget starting on the 1st of the current month.
class CreateBudgetSheet extends ConsumerStatefulWidget {
  const CreateBudgetSheet({super.key});

  static Future<Budget?> show(BuildContext context) {
    return showModalBottomSheet<Budget>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CreateBudgetSheet(),
    );
  }

  @override
  ConsumerState<CreateBudgetSheet> createState() => _CreateBudgetSheetState();
}

class _CreateBudgetSheetState extends ConsumerState<CreateBudgetSheet> {
  final _limitController = TextEditingController();
  Category? _selectedCategory;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _hasPositiveLimit {
    final value = double.tryParse(_limitController.text.trim());
    return value != null && value > 0;
  }

  bool get _canSave =>
      _hasPositiveLimit && _selectedCategory != null && !_isSaving;

  @override
  void initState() {
    super.initState();
    _limitController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _pickCategory() async {
    final category = await CategoryPickerSheet.show(context);
    if (category != null && mounted) {
      setState(() => _selectedCategory = category);
    }
  }

  String _firstOfCurrentMonth() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-01';
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final category = _selectedCategory!;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final created = await ref
          .read(budgetRepositoryProvider)
          .create(
            categoryId: category.id,
            amountLimit: _limitController.text.trim(),
            period: BudgetPeriod.monthly,
            startDate: _firstOfCurrentMonth(),
          );

      if (!mounted) return;
      Navigator.of(context).pop(created);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.budgetCreatedToast)));
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = l10n.errorMessageForCode(
          exception.code,
          exception.message,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
                l10n.createBudgetSheetTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.createBudgetCategoryLabel),
                subtitle: Text(
                  _selectedCategory?.name ??
                      l10n.createBudgetCategoryPlaceholder,
                ),
                leading:
                    _selectedCategory != null
                        ? Icon(_selectedCategory!.iconData)
                        : const Icon(Icons.category_outlined),
                onTap: _pickCategory,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _limitController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.createBudgetLimitLabel,
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
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
                        : Text(l10n.createBudgetSaveButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
