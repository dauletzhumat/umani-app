import 'package:flutter/material.dart';

/// Hand-written for now — the project only needs a handful of strings at
/// this stage. API shape (`.of(context)`, delegate) mirrors what
/// `flutter gen-l10n` would produce, so swapping to the official
/// intl/.arb pipeline later is a drop-in replacement, not a call-site
/// rewrite, once the string count justifies that machinery.
class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('ru'), Locale('kk'), Locale('en')];

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(localizations != null, 'AppLocalizations not found in context');
    return localizations!;
  }

  static const Map<String, Map<String, String>> _strings = {
    'ru': {
      'appName': 'AI Finance',
      'languageScreenTitle': 'Выберите язык',
      'languageRu': 'Русский',
      'languageKk': 'Қазақша',
      'languageEn': 'English',
      'onboardingPlaceholder': 'Онбординг: скоро',
    },
    'kk': {
      'appName': 'AI Finance',
      'languageScreenTitle': 'Тілді таңдаңыз',
      'languageRu': 'Русский',
      'languageKk': 'Қазақша',
      'languageEn': 'English',
      'onboardingPlaceholder': 'Таныстыру: жақында',
    },
    'en': {
      'appName': 'AI Finance',
      'languageScreenTitle': 'Choose your language',
      'languageRu': 'Русский',
      'languageKk': 'Қазақша',
      'languageEn': 'English',
      'onboardingPlaceholder': 'Onboarding: coming soon',
    },
  };

  String _string(String key) =>
      _strings[locale.languageCode]?[key] ?? _strings['ru']![key]!;

  String get appName => _string('appName');
  String get languageScreenTitle => _string('languageScreenTitle');
  String get languageRu => _string('languageRu');
  String get languageKk => _string('languageKk');
  String get languageEn => _string('languageEn');
  String get onboardingPlaceholder => _string('onboardingPlaceholder');
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (supported) => supported.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) =>
      Future.value(AppLocalizations(locale));

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
