import 'dart:async';

import 'package:flutter/material.dart';

/// Brand splash shown on cold start (docs/05_UX.md §2).
///
/// No interactive elements. Session/locale branching after the timeout
/// belongs to T1.7 — here [onTimeout] is a plain hook the caller wires up.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.onTimeout,
    this.duration = const Duration(milliseconds: 1500),
  });

  final VoidCallback? onTimeout;
  final Duration duration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, () => widget.onTimeout?.call());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
