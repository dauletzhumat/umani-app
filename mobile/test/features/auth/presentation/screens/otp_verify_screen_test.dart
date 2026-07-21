import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/app_localizations.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/presentation/screens/otp_verify_screen.dart';

class _ThrowingAuthRepository implements AuthRepository {
  @override
  Future<void> register(String identifier) async {}

  @override
  Future<void> login(String identifier) async {}

  @override
  Future<VerifyOtpResult> verifyOtp(String identifier, String code) async {
    throw const ApiException(code: 'OTP_INVALID', message: 'Invalid code');
  }
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(_ThrowingAuthRepository()),
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
      home: child,
    ),
  );
}

void main() {
  testWidgets(
    'a wrong code shows an inline error without losing the entered phone number',
    (WidgetTester tester) async {
      const identifier = '+77011234567';

      await tester.pumpWidget(
        _wrap(
          OtpVerifyScreen(
            identifier: identifier,
            onVerified: (_) {},
            resendOtp: (_) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Code sent to $identifier'), findsOneWidget);

      for (var i = 0; i < 6; i++) {
        await tester.enterText(find.byType(TextField).at(i), '1');
      }
      await tester.pumpAndSettle();

      expect(find.text('Invalid code'), findsOneWidget);
      // The identifier — entered on the previous screen — is still shown.
      expect(find.text('Code sent to $identifier'), findsOneWidget);
    },
  );
}
