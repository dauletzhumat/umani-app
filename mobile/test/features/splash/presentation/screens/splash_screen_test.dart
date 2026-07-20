import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/splash/presentation/screens/splash_screen.dart';

void main() {
  testWidgets('renders logo/app name and auto-transitions after the timeout', (
    WidgetTester tester,
  ) async {
    var timedOut = false;

    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          duration: const Duration(milliseconds: 500),
          onTimeout: () => timedOut = true,
        ),
      ),
    );

    expect(find.text('AI Finance'), findsOneWidget);
    expect(find.byIcon(Icons.savings_outlined), findsOneWidget);
    expect(timedOut, isFalse);

    await tester.pump(const Duration(milliseconds: 499));
    expect(timedOut, isFalse);

    await tester.pump(const Duration(milliseconds: 1));
    expect(timedOut, isTrue);
  });
}
