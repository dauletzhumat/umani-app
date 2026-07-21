import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/localization/app_localizations.dart';
import 'core/localization/locale_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/screens/auth_choice_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/otp_verify_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/onboarding/presentation/screens/initial_setup_screen.dart';
import 'features/onboarding/presentation/screens/language_screen.dart';
import 'features/onboarding/presentation/screens/onboarding_carousel_screen.dart';
import 'features/splash/presentation/screens/splash_screen.dart';

void main() {
  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'AI Finance',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(
        builder:
            (context) => SplashScreen(
              onFinished: (hasSession) => _afterSplash(context, hasSession),
            ),
      ),
    );
  }

  // Each route builder below rebinds `context` to that route's own content
  // context (a descendant of the Navigator MaterialApp creates internally)
  // rather than reusing the caller's — `App.build`'s context sits above
  // MaterialApp and has no Navigator ancestor, so Navigator.of(context)
  // throws if that outer context leaks into these callbacks instead.
  void _afterSplash(BuildContext context, bool hasSession) {
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder:
            (context) =>
                hasSession
                    ? const _DashboardPlaceholder()
                    : LanguageScreen(
                      onLanguageSelected: () => _afterLanguage(context),
                    ),
      ),
    );
  }

  void _afterLanguage(BuildContext context) {
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder:
            (context) => OnboardingCarouselScreen(
              onFinished: () => _afterOnboarding(context),
            ),
      ),
    );
  }

  void _afterOnboarding(BuildContext context) {
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const _AuthChoiceRoute()),
    );
  }
}

/// docs/04_User_Flows.md §3, Экран 4 — wires AuthChoiceScreen (T1.10) to
/// Register/Login/OTP (T1.9) and to the guest path.
class _AuthChoiceRoute extends ConsumerWidget {
  const _AuthChoiceRoute();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRepository = ref.read(authRepositoryProvider);

    return AuthChoiceScreen(
      onRegisterTap: () => _openRegister(context, authRepository),
      onLoginTap: () => _openLogin(context, authRepository),
      onGuestStarted: () => _afterGuestStarted(context),
    );
  }

  void _openRegister(BuildContext context, AuthRepository authRepository) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (routeContext) => RegisterScreen(
              onOtpSent:
                  (identifier) => _openOtp(
                    routeContext,
                    identifier: identifier,
                    resendOtp: authRepository.register,
                  ),
            ),
      ),
    );
  }

  void _openLogin(BuildContext context, AuthRepository authRepository) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (routeContext) => LoginScreen(
              onOtpSent:
                  (identifier) => _openOtp(
                    routeContext,
                    identifier: identifier,
                    resendOtp: authRepository.login,
                  ),
            ),
      ),
    );
  }

  void _openOtp(
    BuildContext context, {
    required String identifier,
    required Future<void> Function(String identifier) resendOtp,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (routeContext) => OtpVerifyScreen(
              identifier: identifier,
              resendOtp: resendOtp,
              onVerified: (isNewUser) => _afterVerify(routeContext, isNewUser),
            ),
      ),
    );
  }

  void _afterVerify(BuildContext context, bool isNewUser) {
    if (isNewUser) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder:
              (_) => InitialSetupScreen(
                onFinished: () => _afterInitialSetup(context),
              ),
        ),
        (route) => false,
      );
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const _DashboardPlaceholder()),
      (route) => false,
    );
  }

  void _afterGuestStarted(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder:
            (_) => InitialSetupScreen(
              onFinished: () => _afterInitialSetup(context),
            ),
      ),
      (route) => false,
    );
  }

  void _afterInitialSetup(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const _DashboardPlaceholder()),
      (route) => false,
    );
  }
}

/// Stand-in until Dashboard (M8) exists.
class _DashboardPlaceholder extends StatelessWidget {
  const _DashboardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Dashboard: TODO')));
  }
}
