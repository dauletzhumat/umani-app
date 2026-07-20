import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Language isn't sensitive data — SharedPreferences (not secure storage)
/// is the right store for it.
class LocaleRepository {
  static const _key = 'app_locale';

  Future<Locale?> readLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    return code == null ? null : Locale(code);
  }

  Future<void> writeLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }
}
