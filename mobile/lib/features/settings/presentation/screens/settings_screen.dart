import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/network/token_manager.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../widgets/notification_toggles.dart';

const _currencies = ['KZT', 'USD', 'RUB', 'EUR'];

/// Settings (T10.2, docs/05_UX.md §11) — the MVP-trimmed section list from
/// docs/MVP_Spec.md: profile, language, default currency, notification
/// toggles, delete account (no Тариф/Счета и семейный доступ/Безопасность).
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  String? _selectedCurrency;
  bool _initializedFromProfile = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final l10n = AppLocalizations.of(context);
    await ref
        .read(userRepositoryProvider)
        .updateProfile(
          name: _nameController.text,
          defaultCurrency: _selectedCurrency,
        );
    ref.invalidate(userProfileProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.settingsProfileSaved)));
  }

  Future<void> _confirmDeleteAccount() async {
    final l10n = AppLocalizations.of(context);

    // Double confirmation + explained consequences, one tap deep from the
    // Settings screen itself — 05_UX.md §11 explicitly forbids hiding
    // account deletion behind dark-pattern-style extra steps.
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(l10n.settingsDeleteAccountConfirmTitle),
            content: Text(l10n.settingsDeleteAccountConfirmMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.settingsDeleteAccountCancelButton),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.settingsDeleteAccountConfirmButton),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    final scheduledPurgeAt = await ref
        .read(userRepositoryProvider)
        .deleteAccount();
    await ref.read(tokenManagerProvider).clear();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(l10n.settingsDeleteAccountScheduledTitle),
            content: Text(
              l10n.settingsDeleteAccountScheduledMessage(
                _formatDate(scheduledPurgeAt),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.settingsDeleteAccountScheduledOk),
              ),
            ],
          ),
    );
  }

  String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate).toLocal();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider);
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsScreenTitle)),
      body: profileAsync.when(
        data: (profile) {
          if (!_initializedFromProfile) {
            _nameController.text = profile.name ?? '';
            _selectedCurrency = profile.defaultCurrency;
            _initializedFromProfile = true;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l10n.settingsSectionProfile, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l10n.settingsNameLabel),
              ),
              if (profile.phone != null) ...[
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.settingsPhoneLabel),
                  subtitle: Text(profile.phone!),
                ),
              ],
              if (profile.email != null) ...[
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.settingsEmailLabel),
                  subtitle: Text(profile.email!),
                ),
              ],
              const SizedBox(height: 8),
              Text(l10n.settingsCurrencyLabel),
              const SizedBox(height: 8),
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
              FilledButton(
                onPressed: _saveProfile,
                child: Text(l10n.settingsSaveProfile),
              ),
              const Divider(height: 32),
              Text(l10n.settingsSectionLanguage, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(l10n.languageRu),
                    selected: currentLocale.languageCode == 'ru',
                    onSelected:
                        (_) => ref
                            .read(localeProvider.notifier)
                            .setLocale(const Locale('ru')),
                  ),
                  ChoiceChip(
                    label: Text(l10n.languageKk),
                    selected: currentLocale.languageCode == 'kk',
                    onSelected:
                        (_) => ref
                            .read(localeProvider.notifier)
                            .setLocale(const Locale('kk')),
                  ),
                  ChoiceChip(
                    label: Text(l10n.languageEn),
                    selected: currentLocale.languageCode == 'en',
                    onSelected:
                        (_) => ref
                            .read(localeProvider.notifier)
                            .setLocale(const Locale('en')),
                  ),
                ],
              ),
              const Divider(height: 32),
              Text(
                l10n.settingsSectionNotifications,
                style: theme.textTheme.titleMedium,
              ),
              const NotificationToggles(),
              const Divider(height: 32),
              Text(l10n.settingsSectionData, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                onPressed: _confirmDeleteAccount,
                child: Text(l10n.settingsDeleteAccount),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(l10n.errorNetwork)),
      ),
    );
  }
}
