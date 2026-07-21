import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/repositories/account_repository_impl.dart';
import '../../domain/entities/account.dart';
import '../widgets/account_carousel.dart';
import 'account_detail_screen.dart';

/// Wallet screen (docs/05_UX.md §5): carousel of accounts, or a dedicated
/// empty state when the user has none yet. Net worth summary, the unified
/// transaction feed, and tap-to-filter-the-feed are not built here — the
/// feed doesn't exist until M4, and net worth needs FX conversion for
/// multi-currency users (💎, out of MVP scope). Tapping an account opens
/// its detail screen instead of filtering a feed, since there's no feed
/// yet to filter.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  void _openAddAccountSheet(BuildContext context) {
    // T3.3 wires the actual "add account" Bottom Sheet here.
  }

  void _openAccountDetail(BuildContext context, Account account) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AccountDetailScreen(account: account)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final accountsAsync = ref.watch(accountListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.walletTitle)),
      body: accountsAsync.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return _EmptyState(
              message: l10n.walletEmptyStateMessage,
              buttonLabel: l10n.walletAddAccountButton,
              onAddAccountTap: () => _openAddAccountSheet(context),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: AccountCarousel(
              accounts: accounts,
              onAccountTap: (account) => _openAccountDetail(context, account),
              onAddAccountTap: () => _openAddAccountSheet(context),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(l10n.errorNetwork)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.message,
    required this.buttonLabel,
    required this.onAddAccountTap,
  });

  final String message;
  final String buttonLabel;
  final VoidCallback onAddAccountTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_balance_wallet_outlined, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAddAccountTap,
              child: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
