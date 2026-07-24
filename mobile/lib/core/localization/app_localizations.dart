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
      'authContinueAsGuest': 'Продолжить как гость',
      'otpTitle': 'Подтверждение кода',
      'otpSentTo': 'Код отправлен на {value}',
      'otpVerifyButton': 'Подтвердить',
      'otpResend': 'Отправить код повторно',
      'otpResendIn': 'Повторная отправка через {value} с',
      'initialSetupCurrencyTitle': 'Выберите основную валюту',
      'initialSetupMultiCurrencyToggle':
          'Буду использовать несколько валют',
      'initialSetupGoalsTitle': 'Зачем вам AI Finance?',
      'goalUnderstandSpending': 'Понять, куда уходят деньги',
      'goalSaveForTarget': 'Накопить на цель',
      'goalManageInstallments': 'Разобраться с рассрочками/долгами',
      'goalFamilyBudget': 'Вести бюджет с семьёй/партнёром',
      'goalInvestments': 'Инвестиции и net worth',
      'errorOtpInvalid': 'Неверный код',
      'errorOtpExpired': 'Код истёк, запросите новый',
      'errorTooManyAttempts':
          'Слишком много попыток, запросите новый код',
      'errorUserAlreadyExists':
          'Этот номер уже зарегистрирован — попробуйте войти',
      'errorUserNotFound': 'Аккаунт с этим номером не найден',
      'errorValidation': 'Проверьте правильность введённых данных',
      'errorNetwork': 'Не удалось подключиться, проверьте соединение',
      'categoryPickerTitle': 'Выберите категорию',
      'categoryPickerCreateNew': '+ Своя категория',
      'categoryCreateNameLabel': 'Название',
      'categoryCreateButton': 'Создать',
      'categoryCreateCancel': 'Отмена',
      'walletTitle': 'Кошелёк',
      'walletEmptyStateMessage': 'Здесь появятся ваши счета',
      'walletAddAccountButton': 'Добавить счёт',
      'walletAddAccountCard': '+ Добавить счёт',
      'accountDetailTitle': 'Детали счёта',
      'accountDetailArchive': 'Архивировать счёт',
      'accountDetailUnarchive': 'Вернуть из архива',
      'addAccountSheetTitle': 'Добавить счёт',
      'addAccountOptionCash': 'Наличные',
      'addAccountOptionManual': 'Ручной счёт',
      'addAccountNameLabel': 'Название',
      'addAccountCurrencyLabel': 'Валюта',
      'addAccountTypeLabel': 'Тип счёта',
      'addAccountTypeBank': 'Банк',
      'addAccountTypeCard': 'Карта',
      'addAccountSaveButton': 'Сохранить',
      'addTransactionSheetTitle': 'Добавить транзакцию',
      'addTransactionManual': 'Вручную',
      'addTransactionPhoto': 'Фото чека',
      'addTransactionTemplate': 'Из шаблона',
      'manualEntryTitle': 'Новая транзакция',
      'manualEntryTypeIncome': 'Доход',
      'manualEntryTypeExpense': 'Расход',
      'manualEntryAmountLabel': 'Сумма',
      'manualEntryCategoryLabel': 'Категория',
      'manualEntryCategoryPlaceholder': 'Выбрать категорию',
      'manualEntryAccountLabel': 'Счёт',
      'manualEntryDateLabel': 'Дата',
      'manualEntryNoteLabel': 'Заметка',
      'manualEntrySaveButton': 'Сохранить',
      'transactionSavedToast': 'Транзакция сохранена',
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
      'authContinueAsGuest': 'Қонақ ретінде жалғастыру',
      'otpTitle': 'Кодты растау',
      'otpSentTo': 'Код мына мекенжайға жіберілді: {value}',
      'otpVerifyButton': 'Растау',
      'otpResend': 'Кодты қайта жіберу',
      'otpResendIn': 'Қайта жіберу: {value} с кейін',
      'initialSetupCurrencyTitle': 'Негізгі валютаны таңдаңыз',
      'initialSetupMultiCurrencyToggle': 'Бірнеше валюта қолданамын',
      'initialSetupGoalsTitle': 'AI Finance сізге не үшін керек?',
      'goalUnderstandSpending': 'Ақша қайда кететінін түсіну',
      'goalSaveForTarget': 'Мақсатқа ақша жинау',
      'goalManageInstallments': 'Бөліп төлеулерді/қарыздарды реттеу',
      'goalFamilyBudget': 'Отбасымен/серіктеспен бюджет жүргізу',
      'goalInvestments': 'Инвестициялар және net worth',
      'errorOtpInvalid': 'Код қате',
      'errorOtpExpired': 'Кодтың мерзімі өтті, жаңасын сұраңыз',
      'errorTooManyAttempts': 'Тым көп әрекет, жаңа код сұраңыз',
      'errorUserAlreadyExists': 'Бұл нөмір тіркелген — кіріп көріңіз',
      'errorUserNotFound': 'Бұл нөмірмен аккаунт табылмады',
      'errorValidation': 'Енгізген деректерді тексеріңіз',
      'errorNetwork': 'Қосылу мүмкін болмады, желіні тексеріңіз',
      'categoryPickerTitle': 'Санатты таңдаңыз',
      'categoryPickerCreateNew': '+ Жеке санат',
      'categoryCreateNameLabel': 'Атауы',
      'categoryCreateButton': 'Жасау',
      'categoryCreateCancel': 'Бас тарту',
      'walletTitle': 'Әмиян',
      'walletEmptyStateMessage': 'Мұнда сіздің шоттарыңыз пайда болады',
      'walletAddAccountButton': 'Шот қосу',
      'walletAddAccountCard': '+ Шот қосу',
      'accountDetailTitle': 'Шот туралы мәлімет',
      'accountDetailArchive': 'Шотты мұрағаттау',
      'accountDetailUnarchive': 'Мұрағаттан қайтару',
      'addAccountSheetTitle': 'Шот қосу',
      'addAccountOptionCash': 'Қолма-қол ақша',
      'addAccountOptionManual': 'Қолмен енгізілетін шот',
      'addAccountNameLabel': 'Атауы',
      'addAccountCurrencyLabel': 'Валюта',
      'addAccountTypeLabel': 'Шот түрі',
      'addAccountTypeBank': 'Банк',
      'addAccountTypeCard': 'Карта',
      'addAccountSaveButton': 'Сақтау',
      'addTransactionSheetTitle': 'Транзакция қосу',
      'addTransactionManual': 'Қолмен',
      'addTransactionPhoto': 'Чек фотосы',
      'addTransactionTemplate': 'Үлгіден',
      'manualEntryTitle': 'Жаңа транзакция',
      'manualEntryTypeIncome': 'Кіріс',
      'manualEntryTypeExpense': 'Шығыс',
      'manualEntryAmountLabel': 'Сома',
      'manualEntryCategoryLabel': 'Санат',
      'manualEntryCategoryPlaceholder': 'Санатты таңдау',
      'manualEntryAccountLabel': 'Шот',
      'manualEntryDateLabel': 'Күні',
      'manualEntryNoteLabel': 'Ескертпе',
      'manualEntrySaveButton': 'Сақтау',
      'transactionSavedToast': 'Транзакция сақталды',
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
      'authContinueAsGuest': 'Continue as guest',
      'otpTitle': 'Verify code',
      'otpSentTo': 'Code sent to {value}',
      'otpVerifyButton': 'Verify',
      'otpResend': 'Resend code',
      'otpResendIn': 'Resend in {value}s',
      'initialSetupCurrencyTitle': 'Choose your main currency',
      'initialSetupMultiCurrencyToggle': "I'll use multiple currencies",
      'initialSetupGoalsTitle': 'Why AI Finance?',
      'goalUnderstandSpending': 'Understand where money goes',
      'goalSaveForTarget': 'Save up for a goal',
      'goalManageInstallments': 'Get a handle on installments/debt',
      'goalFamilyBudget': 'Budget with family/partner',
      'goalInvestments': 'Investments and net worth',
      'errorOtpInvalid': 'Invalid code',
      'errorOtpExpired': 'Code expired, request a new one',
      'errorTooManyAttempts': 'Too many attempts, request a new code',
      'errorUserAlreadyExists':
          'This identifier is already registered — try logging in',
      'errorUserNotFound': 'No account found for this identifier',
      'errorValidation': 'Please check what you entered',
      'errorNetwork': 'Could not connect, check your connection',
      'categoryPickerTitle': 'Choose a category',
      'categoryPickerCreateNew': '+ Custom category',
      'categoryCreateNameLabel': 'Name',
      'categoryCreateButton': 'Create',
      'categoryCreateCancel': 'Cancel',
      'walletTitle': 'Wallet',
      'walletEmptyStateMessage': 'Your accounts will show up here',
      'walletAddAccountButton': 'Add account',
      'walletAddAccountCard': '+ Add account',
      'accountDetailTitle': 'Account details',
      'accountDetailArchive': 'Archive account',
      'accountDetailUnarchive': 'Unarchive',
      'addAccountSheetTitle': 'Add account',
      'addAccountOptionCash': 'Cash',
      'addAccountOptionManual': 'Manual account',
      'addAccountNameLabel': 'Name',
      'addAccountCurrencyLabel': 'Currency',
      'addAccountTypeLabel': 'Account type',
      'addAccountTypeBank': 'Bank',
      'addAccountTypeCard': 'Card',
      'addAccountSaveButton': 'Save',
      'addTransactionSheetTitle': 'Add transaction',
      'addTransactionManual': 'Manually',
      'addTransactionPhoto': 'Photo of receipt',
      'addTransactionTemplate': 'From template',
      'manualEntryTitle': 'New transaction',
      'manualEntryTypeIncome': 'Income',
      'manualEntryTypeExpense': 'Expense',
      'manualEntryAmountLabel': 'Amount',
      'manualEntryCategoryLabel': 'Category',
      'manualEntryCategoryPlaceholder': 'Choose a category',
      'manualEntryAccountLabel': 'Account',
      'manualEntryDateLabel': 'Date',
      'manualEntryNoteLabel': 'Note',
      'manualEntrySaveButton': 'Save',
      'transactionSavedToast': 'Transaction saved',
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
  String get authContinueAsGuest => _string('authContinueAsGuest');

  String get otpTitle => _string('otpTitle');
  String otpSentTo(String identifier) => _template('otpSentTo', identifier);
  String get otpVerifyButton => _string('otpVerifyButton');
  String get otpResend => _string('otpResend');
  String otpResendIn(int seconds) =>
      _template('otpResendIn', seconds.toString());

  String get initialSetupCurrencyTitle =>
      _string('initialSetupCurrencyTitle');
  String get initialSetupMultiCurrencyToggle =>
      _string('initialSetupMultiCurrencyToggle');
  String get initialSetupGoalsTitle => _string('initialSetupGoalsTitle');
  String get goalUnderstandSpending => _string('goalUnderstandSpending');
  String get goalSaveForTarget => _string('goalSaveForTarget');
  String get goalManageInstallments => _string('goalManageInstallments');
  String get goalFamilyBudget => _string('goalFamilyBudget');
  String get goalInvestments => _string('goalInvestments');

  String get errorOtpInvalid => _string('errorOtpInvalid');
  String get errorOtpExpired => _string('errorOtpExpired');
  String get errorTooManyAttempts => _string('errorTooManyAttempts');
  String get errorUserAlreadyExists => _string('errorUserAlreadyExists');
  String get errorUserNotFound => _string('errorUserNotFound');
  String get errorValidation => _string('errorValidation');
  String get errorNetwork => _string('errorNetwork');

  String get categoryPickerTitle => _string('categoryPickerTitle');
  String get categoryPickerCreateNew => _string('categoryPickerCreateNew');
  String get categoryCreateNameLabel => _string('categoryCreateNameLabel');
  String get categoryCreateButton => _string('categoryCreateButton');
  String get categoryCreateCancel => _string('categoryCreateCancel');

  String get walletTitle => _string('walletTitle');
  String get walletEmptyStateMessage => _string('walletEmptyStateMessage');
  String get walletAddAccountButton => _string('walletAddAccountButton');
  String get walletAddAccountCard => _string('walletAddAccountCard');
  String get accountDetailTitle => _string('accountDetailTitle');
  String get accountDetailArchive => _string('accountDetailArchive');
  String get accountDetailUnarchive => _string('accountDetailUnarchive');

  String get addAccountSheetTitle => _string('addAccountSheetTitle');
  String get addAccountOptionCash => _string('addAccountOptionCash');
  String get addAccountOptionManual => _string('addAccountOptionManual');
  String get addAccountNameLabel => _string('addAccountNameLabel');
  String get addAccountCurrencyLabel => _string('addAccountCurrencyLabel');
  String get addAccountTypeLabel => _string('addAccountTypeLabel');
  String get addAccountTypeBank => _string('addAccountTypeBank');
  String get addAccountTypeCard => _string('addAccountTypeCard');
  String get addAccountSaveButton => _string('addAccountSaveButton');

  String get addTransactionSheetTitle => _string('addTransactionSheetTitle');
  String get addTransactionManual => _string('addTransactionManual');
  String get addTransactionPhoto => _string('addTransactionPhoto');
  String get addTransactionTemplate => _string('addTransactionTemplate');

  String get manualEntryTitle => _string('manualEntryTitle');
  String get manualEntryTypeIncome => _string('manualEntryTypeIncome');
  String get manualEntryTypeExpense => _string('manualEntryTypeExpense');
  String get manualEntryAmountLabel => _string('manualEntryAmountLabel');
  String get manualEntryCategoryLabel => _string('manualEntryCategoryLabel');
  String get manualEntryCategoryPlaceholder =>
      _string('manualEntryCategoryPlaceholder');
  String get manualEntryAccountLabel => _string('manualEntryAccountLabel');
  String get manualEntryDateLabel => _string('manualEntryDateLabel');
  String get manualEntryNoteLabel => _string('manualEntryNoteLabel');
  String get manualEntrySaveButton => _string('manualEntrySaveButton');
  String get transactionSavedToast => _string('transactionSavedToast');

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
