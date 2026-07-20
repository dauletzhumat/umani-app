import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/splash/presentation/screens/splash_screen.dart';

void main() {
  testWidgets(
    'renders logo/app name and auto-transitions after the timeout, reporting the session result',
    (WidgetTester tester) async {
      bool? finishedWithSession;

      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            duration: const Duration(milliseconds: 500),
            checkSession: () async => true,
            onFinished: (hasSession) => finishedWithSession = hasSession,
          ),
        ),
      );

      expect(find.text('AI Finance'), findsOneWidget);
      expect(find.byIcon(Icons.savings_outlined), findsOneWidget);
      expect(finishedWithSession, isNull);

      await tester.pump(const Duration(milliseconds: 499));
      expect(finishedWithSession, isNull);

      await tester.pump(const Duration(milliseconds: 1));
      expect(finishedWithSession, isTrue);
    },
  );

  testWidgets('reports no session when checkSession resolves false', (
    WidgetTester tester,
  ) async {
    bool? finishedWithSession;

    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          duration: const Duration(milliseconds: 100),
          checkSession: () async => false,
          onFinished: (hasSession) => finishedWithSession = hasSession,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(finishedWithSession, isFalse);
  });
}
