import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only for now, same pattern as LocaleRepository (T1.7).
///
/// Currency: PATCH /users/me (T1.6) already accepts defaultCurrency and
/// works for registered users — wiring that up is a natural follow-up,
/// not done here, since it'd need to branch on guest vs. registered (a
/// guest's token has no `users` row to PATCH) and neither the file list
/// nor the test-plan for this task calls for it.
///
/// Usage goals: there's no backend field for this anywhere in the schema
/// (docs/07_Database.md's `users` table has no such column) — local
/// storage is the only place these can live until one exists.
class InitialSetupRepository {
  static const _currencyKey = 'initial_setup_currency';
  static const _multiCurrencyKey = 'initial_setup_multi_currency';
  static const _goalsKey = 'initial_setup_usage_goals';

  static const defaultCurrency = 'KZT';

  Future<void> saveCurrency(String currencyCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currencyCode);
  }

  Future<String> readCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currencyKey) ?? defaultCurrency;
  }

  Future<void> saveMultiCurrencyPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_multiCurrencyKey, value);
  }

  Future<bool> readMultiCurrencyPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_multiCurrencyKey) ?? false;
  }

  Future<void> saveUsageGoals(List<String> goalKeys) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_goalsKey, goalKeys);
  }

  Future<List<String>> readUsageGoals() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_goalsKey) ?? const [];
  }
}

final initialSetupRepositoryProvider = Provider<InitialSetupRepository>((
  ref,
) {
  return InitialSetupRepository();
});
