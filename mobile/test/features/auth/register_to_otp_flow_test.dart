import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/app_localizations.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/presentation/screens/otp_verify_screen.dart';
import 'package:mobile/features/auth/presentation/screens/register_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  bool registerCalled = false;

  @override
  Future<void> register(String identifier) async {
    registerCalled = true;
  }

  @override
  Future<void> login(String identifier) async {}

  @override
  Future<String> startGuestSession() async => 'guest-token';

  @override
  Future<VerifyOtpResult> verifyOtp(String identifier, String code) async {
    return const VerifyOtpResult(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      isNewUser: true,
    );
  }
}

/// Mirrors the Register -> OTP -> "initial setup" wiring from main.dart,
/// scoped to just this segment — the test-plan's "регистрация -> OTP ->
/// переход на экран первичной настройки".
class _RegisterFlowHarness extends StatelessWidget {
  const _RegisterFlowHarness();

  @override
  Widget build(BuildContext context) {
    return RegisterScreen(
      onOtpSent: (identifier) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (routeContext) => OtpVerifyScreen(
                  identifier: identifier,
                  resendOtp: (id) async {},
                  onVerified: (isNewUser) {
                    Navigator.of(routeContext).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const _InitialSetupStub(),
                      ),
                      (route) => false,
                    );
                  },
                ),
          ),
        );
      },
    );
  }
}

class _InitialSetupStub extends StatelessWidget {
  const _InitialSetupStub();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('initial-setup-reached')));
  }
}

void main() {
  setUp(() {
    // OtpVerifyScreen persists the refresh token to secure storage on
    // success — mock the plugin channel so that real call doesn't throw
    // in the test environment.
    const channel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
  });

  testWidgets(
    'register -> OTP -> initial setup screen, with the API mocked',
    (WidgetTester tester) async {
      final fakeRepository = _FakeAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepository),
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
            home: const _RegisterFlowHarness(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '+77011234567');
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Get code'));
      await tester.pumpAndSettle();

      expect(fakeRepository.registerCalled, isTrue);
      expect(find.text('Code sent to +77011234567'), findsOneWidget);

      for (var i = 0; i < 6; i++) {
        await tester.enterText(find.byType(TextField).at(i), '1');
      }
      await tester.pumpAndSettle();

      expect(find.text('initial-setup-reached'), findsOneWidget);
    },
  );
}
