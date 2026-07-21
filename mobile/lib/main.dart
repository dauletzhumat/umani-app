import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/localization/app_localizations.dart';
import 'core/localization/locale_provider.dart';
import 'core/theme/app_theme.dart';
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
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const _AuthChoicePlaceholder()));
  }
}

/// Stand-in until the auth-choice screen (T1.10) exists.
class _AuthChoicePlaceholder extends StatelessWidget {
  const _AuthChoicePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(AppLocalizations.of(context).authChoicePlaceholder),
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
