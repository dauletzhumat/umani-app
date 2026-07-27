import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only, same pattern as InitialSetupRepository (T1.12) — there's no
/// backend field anywhere in the schema for granular push preferences
/// (docs/07_Database.md's `devices`/`notifications` tables have none), so
/// these toggles don't affect real push delivery (push_service.dart never
/// reads them); they only gate what NotificationToggles itself shows.
class NotificationPreferencesRepository {
  static const _budgetLimitsKey = 'notif_pref_budget_limits';
  static const _installmentPaymentsKey = 'notif_pref_installment_payments';
  static const _aiInsightsKey = 'notif_pref_ai_insights';
  static const _marketingKey = 'notif_pref_marketing';

  Future<bool> readBudgetLimits() => _read(_budgetLimitsKey);
  Future<void> writeBudgetLimits(bool value) => _write(_budgetLimitsKey, value);

  Future<bool> readInstallmentPayments() => _read(_installmentPaymentsKey);
  Future<void> writeInstallmentPayments(bool value) =>
      _write(_installmentPaymentsKey, value);

  Future<bool> readAiInsights() => _read(_aiInsightsKey);
  Future<void> writeAiInsights(bool value) => _write(_aiInsightsKey, value);

  // Marketing defaults to off — opt-in, not opt-out.
  Future<bool> readMarketing() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_marketingKey) ?? false;
  }

  Future<void> writeMarketing(bool value) => _write(_marketingKey, value);

  Future<bool> _read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? true;
  }

  Future<void> _write(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}

final notificationPreferencesRepositoryProvider =
    Provider<NotificationPreferencesRepository>((ref) {
      return NotificationPreferencesRepository();
    });

typedef NotificationPreferences = ({
  bool budgetLimits,
  bool installmentPayments,
  bool aiInsights,
  bool marketing,
});

final notificationPreferencesProvider =
    FutureProvider<NotificationPreferences>((ref) async {
      final repository = ref.watch(notificationPreferencesRepositoryProvider);
      return (
        budgetLimits: await repository.readBudgetLimits(),
        installmentPayments: await repository.readInstallmentPayments(),
        aiInsights: await repository.readAiInsights(),
        marketing: await repository.readMarketing(),
      );
    });
