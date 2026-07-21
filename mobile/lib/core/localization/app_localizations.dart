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
      'authChoicePlaceholder': 'Регистрация / Вход: скоро',
      'onboardingSkip': 'Пропустить',
      'onboardingNext': 'Далее',
      'onboardingGetStarted': 'Начать',
      'onboardingValue1Title': 'Фиксируй траты за секунды',
      'onboardingValue1Subtitle':
          'Сфотографируй чек или надиктуй трату голосом — остальное сделает AI',
      'onboardingValue2Title': 'Держи под контролем все рассрочки',
      'onboardingValue2Subtitle':
          'Сводная карта долгов по всем рассрочкам — видно всё сразу, без сюрпризов',
      'onboardingValue3Title':
          'AI-помощник, который говорит на твоём языке',
      'onboardingValue3Subtitle':
          'Задавай вопросы о своих финансах на русском, казахском или английском',
    },
    'kk': {
      'appName': 'AI Finance',
      'languageScreenTitle': 'Тілді таңдаңыз',
      'languageRu': 'Русский',
      'languageKk': 'Қазақша',
      'languageEn': 'English',
      'authChoicePlaceholder': 'Тіркелу / Кіру: жақында',
      'onboardingSkip': 'Өткізу',
      'onboardingNext': 'Келесі',
      'onboardingGetStarted': 'Бастау',
      'onboardingValue1Title': 'Шығынды секунд ішінде тіркеп ал',
      'onboardingValue1Subtitle':
          'Чектің фотосын түсір немесе шығынды дауыспен айт — қалғанын AI жасайды',
      'onboardingValue2Title': 'Барлық бөліп төлеулерді бақылауда ұста',
      'onboardingValue2Subtitle':
          'Барлық бөліп төлеулер бойынша борыш картасы — бәрі бір көзқараста, тосынсыздықсыз',
      'onboardingValue3Title': 'Өз тіліңде сөйлейтін AI-көмекші',
      'onboardingValue3Subtitle':
          'Қаржың туралы сұрақтарды орысша, қазақша немесе ағылшынша қой',
    },
    'en': {
      'appName': 'AI Finance',
      'languageScreenTitle': 'Choose your language',
      'languageRu': 'Русский',
      'languageKk': 'Қазақша',
      'languageEn': 'English',
      'authChoicePlaceholder': 'Sign up / Log in: coming soon',
      'onboardingSkip': 'Skip',
      'onboardingNext': 'Next',
      'onboardingGetStarted': 'Get Started',
      'onboardingValue1Title': 'Log expenses in seconds',
      'onboardingValue1Subtitle':
          'Snap a photo of a receipt or say it out loud — AI does the rest',
      'onboardingValue2Title': 'Stay on top of every installment plan',
      'onboardingValue2Subtitle':
          'One summary of all your installment debt — nothing sneaks up on you',
      'onboardingValue3Title': 'An AI assistant that speaks your language',
      'onboardingValue3Subtitle':
          'Ask about your finances in Russian, Kazakh, or English',
    },
  };

  String _string(String key) =>
      _strings[locale.languageCode]?[key] ?? _strings['ru']![key]!;

  String get appName => _string('appName');
  String get languageScreenTitle => _string('languageScreenTitle');
  String get languageRu => _string('languageRu');
  String get languageKk => _string('languageKk');
  String get languageEn => _string('languageEn');
  String get authChoicePlaceholder => _string('authChoicePlaceholder');
  String get onboardingSkip => _string('onboardingSkip');
  String get onboardingNext => _string('onboardingNext');
  String get onboardingGetStarted => _string('onboardingGetStarted');
  String get onboardingValue1Title => _string('onboardingValue1Title');
  String get onboardingValue1Subtitle => _string('onboardingValue1Subtitle');
  String get onboardingValue2Title => _string('onboardingValue2Title');
  String get onboardingValue2Subtitle => _string('onboardingValue2Subtitle');
  String get onboardingValue3Title => _string('onboardingValue3Title');
  String get onboardingValue3Subtitle => _string('onboardingValue3Subtitle');
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
