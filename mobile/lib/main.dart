import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/splash/presentation/screens/splash_screen.dart';

void main() {
  runApp(const ProviderScope(child: App()));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Finance',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: SplashScreen(
        onTimeout: () => _goToPlaceholder(context),
      ),
    );
  }

  void _goToPlaceholder(BuildContext context) {
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const _OnboardingPlaceholder()),
    );
  }
}

/// Stand-in until Onboarding (T1.7/T1.8) exists.
class _OnboardingPlaceholder extends StatelessWidget {
  const _OnboardingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Onboarding: TODO')),
    );
  }
}
