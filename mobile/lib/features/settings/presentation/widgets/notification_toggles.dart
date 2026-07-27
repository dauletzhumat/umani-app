import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/repositories/notification_preferences_repository.dart';

/// docs/05_UX.md §11 item 5 — granular toggles, not one "all
/// notifications" switch, so a user can mute noise without losing budget
/// alerts. Local-only (SharedPreferences): no backend field exists for
/// this anywhere in the schema, so these don't gate real push delivery
/// yet — see NotificationPreferencesRepository's doc comment.
class NotificationToggles extends ConsumerWidget {
  const NotificationToggles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final prefsAsync = ref.watch(notificationPreferencesProvider);

    return prefsAsync.when(
      data: (prefs) {
        return Column(
          children: [
            SwitchListTile(
              title: Text(l10n.settingsNotifBudgetLimits),
              value: prefs.budgetLimits,
              onChanged: (value) async {
                await ref
                    .read(notificationPreferencesRepositoryProvider)
                    .writeBudgetLimits(value);
                ref.invalidate(notificationPreferencesProvider);
              },
            ),
            SwitchListTile(
              title: Text(l10n.settingsNotifInstallmentPayments),
              value: prefs.installmentPayments,
              onChanged: (value) async {
                await ref
                    .read(notificationPreferencesRepositoryProvider)
                    .writeInstallmentPayments(value);
                ref.invalidate(notificationPreferencesProvider);
              },
            ),
            SwitchListTile(
              title: Text(l10n.settingsNotifAiInsights),
              value: prefs.aiInsights,
              onChanged: (value) async {
                await ref
                    .read(notificationPreferencesRepositoryProvider)
                    .writeAiInsights(value);
                ref.invalidate(notificationPreferencesProvider);
              },
            ),
            SwitchListTile(
              title: Text(l10n.settingsNotifMarketing),
              value: prefs.marketing,
              onChanged: (value) async {
                await ref
                    .read(notificationPreferencesRepositoryProvider)
                    .writeMarketing(value);
                ref.invalidate(notificationPreferencesProvider);
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
