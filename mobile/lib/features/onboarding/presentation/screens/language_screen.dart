import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/locale_provider.dart';

/// docs/04_User_Flows.md §2, Экран 2 — RU/KZ/EN, no back button, applies
/// immediately (see LocaleNotifier), then moves on to Onboarding (T1.8).
class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key, required this.onLanguageSelected});

  final VoidCallback onLanguageSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.languageScreenTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: 32),
              _LanguageOption(
                label: l10n.languageRu,
                onTap: () => _select(ref, const Locale('ru')),
              ),
              const SizedBox(height: 12),
              _LanguageOption(
                label: l10n.languageKk,
                onTap: () => _select(ref, const Locale('kk')),
              ),
              const SizedBox(height: 12),
              _LanguageOption(
                label: l10n.languageEn,
                onTap: () => _select(ref, const Locale('en')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _select(WidgetRef ref, Locale locale) {
    ref.read(localeProvider.notifier).setLocale(locale);
    onLanguageSelected();
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(onPressed: onTap, child: Text(label)),
    );
  }
}
