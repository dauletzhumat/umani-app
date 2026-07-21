import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/repositories/account_repository_impl.dart';
import '../../domain/entities/account.dart';

/// Account details (docs/05_UX.md §5's "Экран одного счёта"). Only the
/// balance/type display and "Архивировать счёт" are built here — the
/// mini balance chart and manual top-up/withdraw need the transactions
/// table (M4) and T4.3 respectively, and statement import needs OCR;
/// none of that exists yet.
class AccountDetailScreen extends ConsumerStatefulWidget {
  const AccountDetailScreen({super.key, required this.account});

  final Account account;

  @override
  ConsumerState<AccountDetailScreen> createState() =>
      _AccountDetailScreenState();
}

class _AccountDetailScreenState extends ConsumerState<AccountDetailScreen> {
  late Account _account;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _account = widget.account;
  }

  Future<void> _toggleArchived() async {
    setState(() => _isSaving = true);

    final updated = await ref
        .read(accountRepositoryProvider)
        .update(_account.id, archived: !_account.archived);
    ref.invalidate(accountListProvider);

    if (!mounted) return;
    setState(() {
      _account = updated;
      _isSaving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountDetailTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(_account.iconData, size: 48),
            const SizedBox(height: 16),
            Text(_account.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '${_account.balanceCached} ${_account.currency}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _isSaving ? null : _toggleArchived,
              child: Text(
                _account.archived
                    ? l10n.accountDetailUnarchive
                    : l10n.accountDetailArchive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
