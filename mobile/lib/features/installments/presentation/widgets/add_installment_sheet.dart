import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/repositories/installment_repository_impl.dart';
import '../../domain/entities/installment.dart';

/// Bottom Sheet for adding an installment (T7.5, docs/04_User_Flows.md
/// §8's Экран 8.2): merchant, amount, number of payments, start date —
/// the task's own description names exactly these four fields (no
/// provider input).
class AddInstallmentSheet extends ConsumerStatefulWidget {
  const AddInstallmentSheet({super.key});

  static Future<Installment?> show(BuildContext context) {
    return showModalBottomSheet<Installment>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddInstallmentSheet(),
    );
  }

  @override
  ConsumerState<AddInstallmentSheet> createState() =>
      _AddInstallmentSheetState();
}

class _AddInstallmentSheetState extends ConsumerState<AddInstallmentSheet> {
  final _merchantController = TextEditingController();
  final _amountController = TextEditingController();
  final _countController = TextEditingController();
  DateTime _startDate = DateTime.now();
  bool _isSaving = false;

  bool get _hasPositiveAmount {
    final value = double.tryParse(_amountController.text.trim());
    return value != null && value > 0;
  }

  bool get _hasPositiveCount {
    final value = int.tryParse(_countController.text.trim());
    return value != null && value > 0;
  }

  bool get _canSave =>
      _merchantController.text.trim().isNotEmpty &&
      _hasPositiveAmount &&
      _hasPositiveCount &&
      !_isSaving;

  @override
  void initState() {
    super.initState();
    _merchantController.addListener(() => setState(() {}));
    _amountController.addListener(() => setState(() {}));
    _countController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _countController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _isSaving = true);

    final created = await ref
        .read(installmentRepositoryProvider)
        .create(
          merchant: _merchantController.text.trim(),
          totalAmount: _amountController.text.trim(),
          installmentsCount: int.parse(_countController.text.trim()),
          startDate: _startDate.toIso8601String().split('T').first,
        );

    if (!mounted) return;
    Navigator.of(context).pop(created);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.installmentCreatedToast)));
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
                l10n.addInstallmentSheetTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _merchantController,
                decoration: InputDecoration(
                  labelText: l10n.addInstallmentMerchantLabel,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.addInstallmentAmountLabel,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _countController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.addInstallmentCountLabel,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.addInstallmentStartDateLabel),
                subtitle: Text(
                  '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
                ),
                leading: const Icon(Icons.calendar_today_outlined),
                onTap: _pickStartDate,
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
                        : Text(l10n.addInstallmentSaveButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
