import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/app_localizations.dart';
import 'package:mobile/features/onboarding/presentation/screens/onboarding_carousel_screen.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizationsDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: child,
  );
}

void main() {
  testWidgets('swiping switches slides', (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(OnboardingCarouselScreen(onFinished: () {})),
    );
    await tester.pumpAndSettle();

    expect(find.text('Log expenses in seconds'), findsOneWidget);
    expect(find.text('Stay on top of every installment plan'), findsNothing);

    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(find.text('Log expenses in seconds'), findsNothing);
    expect(find.text('Stay on top of every installment plan'), findsOneWidget);
  });

  testWidgets('"Skip" from a slide other than the first still finishes onboarding', (
    WidgetTester tester,
  ) async {
    var finished = false;

    await tester.pumpWidget(
      _wrap(OnboardingCarouselScreen(onFinished: () => finished = true)),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Stay on top of every installment plan'), findsOneWidget);
    expect(finished, isFalse);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(finished, isTrue);
  });

  testWidgets('"Next" advances slides and becomes "Get Started" on the last one', (
    WidgetTester tester,
  ) async {
    var finished = false;

    await tester.pumpWidget(
      _wrap(OnboardingCarouselScreen(onFinished: () => finished = true)),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Next'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();

    expect(find.text('An AI assistant that speaks your language'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Get Started'), findsOneWidget);
    expect(finished, isFalse);

    await tester.tap(find.widgetWithText(FilledButton, 'Get Started'));
    await tester.pumpAndSettle();

    expect(finished, isTrue);
  });
}
