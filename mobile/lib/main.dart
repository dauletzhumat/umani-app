import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/localization/app_localizations.dart';
import 'core/localization/locale_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/otp_verify_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
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
      home: SplashScreen(
        onFinished: (hasSession) => _afterSplash(context, hasSession),
      ),
    );
  }

  void _afterSplash(BuildContext context, bool hasSession) {
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
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
            (_) => OnboardingCarouselScreen(
              onFinished: () => _afterOnboarding(context),
            ),
      ),
    );
  }

  void _afterOnboarding(BuildContext context) {
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const _AuthChoiceStub()),
    );
  }
}

/// Stand-in for the real auth-choice screen (T1.10, which also adds
/// "Продолжить как гость"). Just enough to reach Register/Login/OTP,
/// built in T1.9, from a running app.
class _AuthChoiceStub extends ConsumerWidget {
  const _AuthChoiceStub();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final authRepository = ref.read(authRepositoryProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton(
                onPressed: () => _openRegister(context, authRepository),
                child: Text(l10n.authSignUpButton),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _openLogin(context, authRepository),
                child: Text(l10n.authLogInButton),
              ),
            ],
          ),
        ),
      ),
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
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder:
            (_) =>
                isNewUser
                    ? const _InitialSetupPlaceholder()
                    : const _DashboardPlaceholder(),
      ),
      (route) => false,
    );
  }
}

/// Stand-in until initial account setup (T1.12) exists.
class _InitialSetupPlaceholder extends StatelessWidget {
  const _InitialSetupPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(AppLocalizations.of(context).initialSetupPlaceholder),
      ),
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
