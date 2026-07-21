import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/account.dart';

/// Horizontal carousel of account cards (docs/05_UX.md §5). The
/// "+ Добавить счёт" card is always appended last, regardless of how
/// many accounts exist.
class AccountCarousel extends StatelessWidget {
  const AccountCarousel({
    super.key,
    required this.accounts,
    required this.onAccountTap,
    required this.onAddAccountTap,
  });

  final List<Account> accounts;
  final ValueChanged<Account> onAccountTap;
  final VoidCallback onAddAccountTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: accounts.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == accounts.length) {
            return _AddAccountCard(
              label: l10n.walletAddAccountCard,
              onTap: onAddAccountTap,
            );
          }
          final account = accounts[index];
          return _AccountCard(
            account: account,
            onTap: () => onAccountTap(account),
          );
        },
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account, required this.onTap});

  final Account account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(account.iconData),
                Text(
                  account.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '${account.balanceCached} ${account.currency}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddAccountCard extends StatelessWidget {
  const _AddAccountCard({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Text(label, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
