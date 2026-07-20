import 'package:flutter/material.dart';
import '../../../../core/storage/session_storage.dart';

/// Brand splash shown on cold start (docs/05_UX.md §2) — also where the
/// session check that decides Dashboard vs. Onboarding happens, per the
/// doc ("пока грузятся начальные данные (проверка сессии, локали)").
///
/// No interactive elements. [checkSession] defaults to a real
/// [SessionStorage] lookup; tests inject a fake instead.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.onFinished,
    this.duration = const Duration(milliseconds: 1500),
    this.checkSession,
  });

  final ValueChanged<bool> onFinished;
  final Duration duration;
  final Future<bool> Function()? checkSession;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final checkSession = widget.checkSession ?? SessionStorage().hasSession;
    final sessionFuture = checkSession();

    await Future<void>.delayed(widget.duration);
    final hasSession = await sessionFuture;

    if (!mounted) return;
    widget.onFinished(hasSession);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.savings_outlined,
              size: 64,
              color: theme.colorScheme.primary,
              semanticLabel: 'AI Finance',
            ),
            const SizedBox(height: 16),
            Text('AI Finance', style: theme.textTheme.titleLarge),
            const SizedBox(height: 32),
            const _LoaderDots(),
          ],
        ),
      ),
    );
  }
}

class _LoaderDots extends StatelessWidget {
  const _LoaderDots();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Padding(
          padding: EdgeInsets.only(left: index == 0 ? 0 : 8),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        );
      }),
    );
  }
}
