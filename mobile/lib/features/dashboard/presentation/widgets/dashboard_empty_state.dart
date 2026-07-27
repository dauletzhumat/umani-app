import 'package:flutter/material.dart';

/// A single widget's empty-state CTA (T8.3, docs/05_UX.md §4:
/// "Empty-Dashboard заменяет виджет бюджетов на CTA 'Создать первый
/// бюджет', а ленту операций — на CTA 'Добавить первую операцию'" —
/// per-widget replacement, not a single full-screen empty state).
class DashboardEmptyState extends StatelessWidget {
  const DashboardEmptyState({
    super.key,
    required this.message,
    required this.buttonLabel,
    required this.onTap,
  });

  final String message;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onTap, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }
}
