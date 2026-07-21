import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/app_localizations.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/presentation/screens/auth_choice_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<void> register(String identifier) async {}

  @override
  Future<void> login(String identifier) async {}

  @override
  Future<VerifyOtpResult> verifyOtp(String identifier, String code) async {
    throw UnimplementedError();
  }

  @override
  Future<String> startGuestSession() async => 'guest-access-token';
}

void main() {
  testWidgets(
    '"Continue as guest" goes straight to initial setup, with no phone input screens along the way',
    (WidgetTester tester) async {
      var registerTapped = false;
      var loginTapped = false;
      var guestStarted = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: AuthChoiceScreen(
              onRegisterTap: () => registerTapped = true,
              onLoginTap: () => loginTapped = true,
              onGuestStarted: () => guestStarted = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No phone/email field anywhere on this screen.
      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.text('Continue as guest'));
      await tester.pumpAndSettle();

      expect(guestStarted, isTrue);
      expect(registerTapped, isFalse);
      expect(loginTapped, isFalse);
    },
  );
}
