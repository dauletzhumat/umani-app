import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/repositories/initial_setup_repository.dart';
import '../../domain/usecases/save_usage_goals.dart';

const _currencies = ['KZT', 'USD', 'RUB', 'EUR'];
const _goalKeys = [
  'understandSpending',
  'saveForTarget',
  'manageInstallments',
  'familyBudget',
  'investments',
];

/// docs/04_User_Flows.md §4, Экраны 4.1+4.2 combined into one two-step
/// wizard (T1.12's file list has a single screen file). Экран 4.3
/// ("подключить источник данных") isn't built here — it isn't in this
/// task's file list or test-plan, and no task in Development_Tasks.md
/// builds it at all.
class InitialSetupScreen extends ConsumerStatefulWidget {
  const InitialSetupScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  ConsumerState<InitialSetupScreen> createState() =>
      _InitialSetupScreenState();
}

class _InitialSetupScreenState extends ConsumerState<InitialSetupScreen> {
  int _step = 0;
  String _selectedCurrency = InitialSetupRepository.defaultCurrency;
  bool _useMultipleCurrencies = false;
  final Set<String> _selectedGoals = {};
  bool _isSaving = false;

  String _goalLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'understandSpending':
        return l10n.goalUnderstandSpending;
      case 'saveForTarget':
        return l10n.goalSaveForTarget;
      case 'manageInstallments':
        return l10n.goalManageInstallments;
      case 'familyBudget':
        return l10n.goalFamilyBudget;
      case 'investments':
        return l10n.goalInvestments;
      default:
        throw ArgumentError('Unknown goal key: $key');
    }
  }

  void _toggleGoal(String key) {
    setState(() {
      if (_selectedGoals.contains(key)) {
        _selectedGoals.remove(key);
      } else {
        _selectedGoals.add(key);
      }
    });
  }

  Future<void> _finish() async {
    setState(() => _isSaving = true);

    final repository = ref.read(initialSetupRepositoryProvider);
    await repository.saveCurrency(_selectedCurrency);
    await repository.saveMultiCurrencyPreference(_useMultipleCurrencies);
    await ref.read(saveUsageGoalsProvider).call(_selectedGoals.toList());

    if (!mounted) return;
    setState(() => _isSaving = false);
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _step == 0 ? _buildCurrencyStep(l10n) : _buildGoalsStep(l10n),
        ),
      ),
    );
  }

  Widget _buildCurrencyStep(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.initialSetupCurrencyTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children:
              _currencies.map((currency) {
                return ChoiceChip(
                  label: Text(currency),
                  selected: _selectedCurrency == currency,
                  onSelected:
                      (_) => setState(() => _selectedCurrency = currency),
                );
              }).toList(),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.initialSetupMultiCurrencyToggle),
          value: _useMultipleCurrencies,
          onChanged:
              (value) => setState(() => _useMultipleCurrencies = value),
        ),
        const Spacer(),
        FilledButton(
          onPressed: () => setState(() => _step = 1),
          child: Text(l10n.onboardingNext),
        ),
      ],
    );
  }

  Widget _buildGoalsStep(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.initialSetupGoalsTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children:
                _goalKeys.map((key) {
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_goalLabel(l10n, key)),
                    value: _selectedGoals.contains(key),
                    onChanged: (_) => _toggleGoal(key),
                  );
                }).toList(),
          ),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _finish,
          child:
              _isSaving
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text(l10n.onboardingGetStarted),
        ),
      ],
    );
  }
}
