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
      'authRegisterTitle': 'Регистрация',
      'authLoginTitle': 'Вход',
      'authIdentifierLabelPhone': 'Номер телефона',
      'authIdentifierLabelEmail': 'Email',
      'authUseEmail': 'Использовать email',
      'authUsePhone': 'Использовать телефон',
      'authPrivacyAgreement': 'Я согласен с политикой конфиденциальности',
      'authGetCode': 'Получить код',
      'authGetLoginCode': 'Получить код входа',
      'authRegisterLink': 'Регистрация',
      'authSignUpButton': 'Зарегистрироваться',
      'authLogInButton': 'Войти',
      'otpTitle': 'Подтверждение кода',
      'otpSentTo': 'Код отправлен на {value}',
      'otpVerifyButton': 'Подтвердить',
      'otpResend': 'Отправить код повторно',
      'otpResendIn': 'Повторная отправка через {value} с',
      'initialSetupPlaceholder': 'Первичная настройка: скоро',
      'errorOtpInvalid': 'Неверный код',
      'errorOtpExpired': 'Код истёк, запросите новый',
      'errorTooManyAttempts':
          'Слишком много попыток, запросите новый код',
      'errorUserAlreadyExists':
          'Этот номер уже зарегистрирован — попробуйте войти',
      'errorUserNotFound': 'Аккаунт с этим номером не найден',
      'errorValidation': 'Проверьте правильность введённых данных',
      'errorNetwork': 'Не удалось подключиться, проверьте соединение',
    },
    'kk': {
      'appName': 'AI Finance',
      'languageScreenTitle': 'Тілді таңдаңыз',
      'languageRu': 'Русский',
      'languageKk': 'Қазақша',
      'languageEn': 'English',
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
      'authRegisterTitle': 'Тіркелу',
      'authLoginTitle': 'Кіру',
      'authIdentifierLabelPhone': 'Телефон нөірі',
      'authIdentifierLabelEmail': 'Email',
      'authUseEmail': 'Email пайдалану',
      'authUsePhone': 'Телефон пайдалану',
      'authPrivacyAgreement': 'Құпиялылық саясатымен келісемін',
      'authGetCode': 'Кодты алу',
      'authGetLoginCode': 'Кіру кодын алу',
      'authRegisterLink': 'Тіркелу',
      'authSignUpButton': 'Тіркелу',
      'authLogInButton': 'Кіру',
      'otpTitle': 'Кодты растау',
      'otpSentTo': 'Код мына мекенжайға жіберілді: {value}',
      'otpVerifyButton': 'Растау',
      'otpResend': 'Кодты қайта жіберу',
      'otpResendIn': 'Қайта жіберу: {value} с кейін',
      'initialSetupPlaceholder': 'Бастапқы баптау: жақында',
      'errorOtpInvalid': 'Код қате',
      'errorOtpExpired': 'Кодтың мерзімі өтті, жаңасын сұраңыз',
      'errorTooManyAttempts': 'Тым көп әрекет, жаңа код сұраңыз',
      'errorUserAlreadyExists': 'Бұл нөмір тіркелген — кіріп көріңіз',
      'errorUserNotFound': 'Бұл нөмірмен аккаунт табылмады',
      'errorValidation': 'Енгізген деректерді тексеріңіз',
      'errorNetwork': 'Қосылу мүмкін болмады, желіні тексеріңіз',
    },
    'en': {
      'appName': 'AI Finance',
      'languageScreenTitle': 'Choose your language',
      'languageRu': 'Русский',
      'languageKk': 'Қазақша',
      'languageEn': 'English',
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
      'authRegisterTitle': 'Sign up',
      'authLoginTitle': 'Log in',
      'authIdentifierLabelPhone': 'Phone number',
      'authIdentifierLabelEmail': 'Email',
      'authUseEmail': 'Use email instead',
      'authUsePhone': 'Use phone instead',
      'authPrivacyAgreement': 'I agree to the privacy policy',
      'authGetCode': 'Get code',
      'authGetLoginCode': 'Get login code',
      'authRegisterLink': 'Sign up',
      'authSignUpButton': 'Sign up',
      'authLogInButton': 'Log in',
      'otpTitle': 'Verify code',
      'otpSentTo': 'Code sent to {value}',
      'otpVerifyButton': 'Verify',
      'otpResend': 'Resend code',
      'otpResendIn': 'Resend in {value}s',
      'initialSetupPlaceholder': 'Initial setup: coming soon',
      'errorOtpInvalid': 'Invalid code',
      'errorOtpExpired': 'Code expired, request a new one',
      'errorTooManyAttempts': 'Too many attempts, request a new code',
      'errorUserAlreadyExists':
          'This identifier is already registered — try logging in',
      'errorUserNotFound': 'No account found for this identifier',
      'errorValidation': 'Please check what you entered',
      'errorNetwork': 'Could not connect, check your connection',
    },
  };

  String _string(String key) =>
      _strings[locale.languageCode]?[key] ?? _strings['ru']![key]!;

  String _template(String key, String value) =>
      _string(key).replaceAll('{value}', value);

  String get appName => _string('appName');
  String get languageScreenTitle => _string('languageScreenTitle');
  String get languageRu => _string('languageRu');
  String get languageKk => _string('languageKk');
  String get languageEn => _string('languageEn');
  String get onboardingSkip => _string('onboardingSkip');
  String get onboardingNext => _string('onboardingNext');
  String get onboardingGetStarted => _string('onboardingGetStarted');
  String get onboardingValue1Title => _string('onboardingValue1Title');
  String get onboardingValue1Subtitle => _string('onboardingValue1Subtitle');
  String get onboardingValue2Title => _string('onboardingValue2Title');
  String get onboardingValue2Subtitle => _string('onboardingValue2Subtitle');
  String get onboardingValue3Title => _string('onboardingValue3Title');
  String get onboardingValue3Subtitle => _string('onboardingValue3Subtitle');

  String get authRegisterTitle => _string('authRegisterTitle');
  String get authLoginTitle => _string('authLoginTitle');
  String get authIdentifierLabelPhone => _string('authIdentifierLabelPhone');
  String get authIdentifierLabelEmail => _string('authIdentifierLabelEmail');
  String get authUseEmail => _string('authUseEmail');
  String get authUsePhone => _string('authUsePhone');
  String get authPrivacyAgreement => _string('authPrivacyAgreement');
  String get authGetCode => _string('authGetCode');
  String get authGetLoginCode => _string('authGetLoginCode');
  String get authRegisterLink => _string('authRegisterLink');
  String get authSignUpButton => _string('authSignUpButton');
  String get authLogInButton => _string('authLogInButton');

  String get otpTitle => _string('otpTitle');
  String otpSentTo(String identifier) => _template('otpSentTo', identifier);
  String get otpVerifyButton => _string('otpVerifyButton');
  String get otpResend => _string('otpResend');
  String otpResendIn(int seconds) =>
      _template('otpResendIn', seconds.toString());

  String get initialSetupPlaceholder => _string('initialSetupPlaceholder');

  String get errorOtpInvalid => _string('errorOtpInvalid');
  String get errorOtpExpired => _string('errorOtpExpired');
  String get errorTooManyAttempts => _string('errorTooManyAttempts');
  String get errorUserAlreadyExists => _string('errorUserAlreadyExists');
  String get errorUserNotFound => _string('errorUserNotFound');
  String get errorValidation => _string('errorValidation');
  String get errorNetwork => _string('errorNetwork');

  /// Maps a backend error `code` (docs/08_API.md §5) to localized text,
  /// falling back to the raw message the server sent for anything not
  /// mapped here (only OTP/register/login codes are covered — that's all
  /// this screen set can produce).
  String errorMessageForCode(String code, String fallback) {
    switch (code) {
      case 'OTP_INVALID':
        return errorOtpInvalid;
      case 'OTP_EXPIRED':
        return errorOtpExpired;
      case 'TOO_MANY_ATTEMPTS':
        return errorTooManyAttempts;
      case 'USER_ALREADY_EXISTS':
        return errorUserAlreadyExists;
      case 'NOT_FOUND':
        return errorUserNotFound;
      case 'VALIDATION_ERROR':
        return errorValidation;
      case 'NETWORK_ERROR':
        return errorNetwork;
      default:
        return fallback;
    }
  }
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
