import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/account.dart';
import '../../domain/usecases/create_account.dart';

const _manualCurrencies = ['KZT', 'USD', 'RUB', 'EUR'];

/// Cash accounts default to KZT, same as T1.12's initial-setup default —
/// there's no per-user default-currency lookup wired into the mobile
/// client yet.
const _cashDefaultCurrency = 'KZT';

enum _Step { chooseOption, cashForm, manualForm }

/// Bottom Sheet for adding an account (docs/05_UX.md §5), limited to the
/// two variants named in this task's own description — "Наличные" and
/// "Ручной счёт". The other two variants documented in 05_UX.md
/// ("Импортировать выписку банка" 🤖, "Мультивалютный кошелёк" 💎) need
/// OCR/bank-statement parsing and FX conversion respectively, neither of
/// which exists yet.
class AddAccountSheet extends ConsumerStatefulWidget {
  const AddAccountSheet({super.key});

  static Future<Account?> show(BuildContext context) {
    return showModalBottomSheet<Account>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddAccountSheet(),
    );
  }

  @override
  ConsumerState<AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends ConsumerState<AddAccountSheet> {
  _Step _step = _Step.chooseOption;
  final _nameController = TextEditingController();
  String _currency = _manualCurrencies.first;
  AccountType _type = AccountType.bank;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save({required AccountType type, required String currency}) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);

    final created = await ref
        .read(createAccountProvider)
        .call(type: type, name: name, currency: currency);

    if (!mounted) return;
    Navigator.of(context).pop(created);
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.addAccountSheetTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            switch (_step) {
              _Step.chooseOption => _buildOptions(l10n),
              _Step.cashForm => _buildCashForm(l10n),
              _Step.manualForm => _buildManualForm(l10n),
            },
          ],
        ),
      ),
    );
  }

  Widget _buildOptions(AppLocalizations l10n) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.payments),
          title: Text(l10n.addAccountOptionCash),
          onTap: () => setState(() => _step = _Step.cashForm),
        ),
        ListTile(
          leading: const Icon(Icons.account_balance),
          title: Text(l10n.addAccountOptionManual),
          onTap: () => setState(() => _step = _Step.manualForm),
        ),
      ],
    );
  }

  Widget _buildCashForm(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nameController,
          decoration: InputDecoration(labelText: l10n.addAccountNameLabel),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed:
              _isSaving
                  ? null
                  : () => _save(
                    type: AccountType.cash,
                    currency: _cashDefaultCurrency,
                  ),
          child:
              _isSaving
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text(l10n.addAccountSaveButton),
        ),
      ],
    );
  }

  Widget _buildManualForm(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nameController,
          decoration: InputDecoration(labelText: l10n.addAccountNameLabel),
        ),
        const SizedBox(height: 12),
        Text(l10n.addAccountTypeLabel, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(l10n.addAccountTypeBank),
              selected: _type == AccountType.bank,
              onSelected: (_) => setState(() => _type = AccountType.bank),
            ),
            ChoiceChip(
              label: Text(l10n.addAccountTypeCard),
              selected: _type == AccountType.card,
              onSelected: (_) => setState(() => _type = AccountType.card),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          l10n.addAccountCurrencyLabel,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children:
              _manualCurrencies.map((currency) {
                return ChoiceChip(
                  label: Text(currency),
                  selected: _currency == currency,
                  onSelected: (_) => setState(() => _currency = currency),
                );
              }).toList(),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed:
              _isSaving
                  ? null
                  : () => _save(type: _type, currency: _currency),
          child:
              _isSaving
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text(l10n.addAccountSaveButton),
        ),
      ],
    );
  }
}
