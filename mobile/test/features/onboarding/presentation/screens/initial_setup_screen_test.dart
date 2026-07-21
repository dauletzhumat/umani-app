import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/localization/app_localizations.dart';
import 'package:mobile/features/onboarding/presentation/screens/initial_setup_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: child,
      ),
    );
  }

  testWidgets('currency defaults to KZT and is changeable', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrap(InitialSetupScreen(onFinished: () {})));
    await tester.pumpAndSettle();

    ChoiceChip chipFor(String label) =>
        tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label));

    expect(chipFor('KZT').selected, isTrue);
    expect(chipFor('USD').selected, isFalse);

    await tester.tap(find.widgetWithText(ChoiceChip, 'USD'));
    await tester.pumpAndSettle();

    expect(chipFor('USD').selected, isTrue);
    expect(chipFor('KZT').selected, isFalse);
  });

  testWidgets('multi-selecting goals keeps every tapped goal selected', (
    WidgetTester tester,
  ) async {
    var finished = false;

    await tester.pumpWidget(
      wrap(InitialSetupScreen(onFinished: () => finished = true)),
    );
    await tester.pumpAndSettle();

    // Move past the currency step without changing anything (stays KZT).
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();

    CheckboxListTile checkboxFor(String label) =>
        tester.widget<CheckboxListTile>(
          find.widgetWithText(CheckboxListTile, label),
        );

    await tester.tap(find.text('Understand where money goes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save up for a goal'));
    await tester.pumpAndSettle();

    // Both stay selected — this isn't a single-choice picker.
    expect(checkboxFor('Understand where money goes').value, isTrue);
    expect(checkboxFor('Save up for a goal').value, isTrue);
    expect(checkboxFor('Investments and net worth').value, isFalse);

    await tester.tap(find.widgetWithText(FilledButton, 'Get Started'));
    await tester.pumpAndSettle();

    expect(finished, isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('initial_setup_currency'), 'KZT');
    expect(
      prefs.getStringList('initial_setup_usage_goals'),
      containsAll(['understandSpending', 'saveForTarget']),
    );
    expect(
      prefs.getStringList('initial_setup_usage_goals'),
      hasLength(2),
    );
  });
}
