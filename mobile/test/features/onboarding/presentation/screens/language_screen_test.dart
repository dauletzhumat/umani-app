import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/localization/app_localizations.dart';
import 'package:mobile/core/localization/locale_provider.dart';
import 'package:mobile/features/onboarding/presentation/screens/language_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'selecting a language persists it and applies immediately, without recreating the widget',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: _LocaleAwareApp()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Қазақша'));
      await tester.pumpAndSettle();

      // Applied immediately: the screen's own title (locale-dependent) switched.
      expect(find.text('Тілді таңдаңыз'), findsOneWidget);

      // Persisted: a fresh read reflects the choice, not just in-memory state.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale'), 'kk');
    },
  );
}

/// Mirrors main.dart's App: MaterialApp.locale driven by localeProvider.
class _LocaleAwareApp extends ConsumerWidget {
  const _LocaleAwareApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: LanguageScreen(onLanguageSelected: () {}),
    );
  }
}
