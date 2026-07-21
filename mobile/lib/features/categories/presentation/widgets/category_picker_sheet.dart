import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/entities/category.dart';

/// Bottom Sheet for picking a category (grid of icons), reused from
/// Transactions and Budgets forms per docs/04_User_Flows.md §5's
/// "выбор категории (сетка иконок)". The inline "+ Своя категория" form
/// stays inside this same sheet rather than pushing a new route, so the
/// caller keeps a single Navigator.pop(category) result contract.
class CategoryPickerSheet extends ConsumerStatefulWidget {
  const CategoryPickerSheet({super.key});

  static Future<Category?> show(BuildContext context) {
    return showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => const FractionallySizedBox(
            heightFactor: 0.85,
            child: CategoryPickerSheet(),
          ),
    );
  }

  @override
  ConsumerState<CategoryPickerSheet> createState() =>
      _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends ConsumerState<CategoryPickerSheet> {
  bool _isCreating = false;
  bool _isSaving = false;
  String? _errorMessage;
  String _selectedIcon = 'category';
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitCreate(AppLocalizations l10n) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(categoryRepositoryProvider)
          .create(name: name, icon: _selectedIcon);
      ref.invalidate(categoryListProvider);

      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _isCreating = false;
        _nameController.clear();
        _selectedIcon = 'category';
      });
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
    final categoriesAsync = ref.watch(categoryListProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.categoryPickerTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: categoriesAsync.when(
                data: (categories) => _buildGrid(categories),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(l10n.errorNetwork)),
              ),
            ),
            const SizedBox(height: 16),
            _isCreating
                ? _buildCreateForm(l10n)
                : TextButton(
                  onPressed: () => setState(() => _isCreating = true),
                  child: Text(l10n.categoryPickerCreateNew),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<Category> categories) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return InkWell(
          onTap: () => Navigator.of(context).pop(category),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(child: Icon(category.iconData)),
              const SizedBox(height: 4),
              Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCreateForm(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nameController,
          decoration: InputDecoration(labelText: l10n.categoryCreateNameLabel),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children:
              categoryIconChoices.entries.map((entry) {
                return ChoiceChip(
                  label: Icon(entry.value, size: 20),
                  selected: _selectedIcon == entry.key,
                  onSelected: (_) => setState(() => _selectedIcon = entry.key),
                );
              }).toList(),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed:
                    _isSaving
                        ? null
                        : () => setState(() {
                          _isCreating = false;
                          _errorMessage = null;
                        }),
                child: Text(l10n.categoryCreateCancel),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: _isSaving ? null : () => _submitCreate(l10n),
                child:
                    _isSaving
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Text(l10n.categoryCreateButton),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
