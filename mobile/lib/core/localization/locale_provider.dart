import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_localizations.dart';
import 'locale_repository.dart';

class LocaleNotifier extends Notifier<Locale> {
  final _repository = LocaleRepository();

  @override
  Locale build() {
    // Fire-and-forget: refine to the persisted choice once the (fast)
    // storage read completes; starts from the device locale in the
    // meantime so there's no loading state to model.
    _loadPersisted();
    return _deviceLocale();
  }

  Locale _deviceLocale() {
    final deviceCode = PlatformDispatcher.instance.locale.languageCode;
    final isSupported = AppLocalizations.supportedLocales.any(
      (locale) => locale.languageCode == deviceCode,
    );
    return isSupported ? Locale(deviceCode) : const Locale('ru');
  }

  Future<void> _loadPersisted() async {
    final saved = await _repository.readLocale();
    if (saved != null) {
      state = saved;
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _repository.writeLocale(locale);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);
