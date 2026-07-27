import 'package:flutter/material.dart';

/// A single widget's loading placeholder (T8.3, docs/MVP_Spec.md §10:
/// "параллельная загрузка 4 источников данных не блокирует отрисовку
/// уже готовых виджетов" — each Dashboard widget skeletons
/// independently rather than the whole screen blocking on one
/// spinner).
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key, this.height = 88});

  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height,
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      ),
    );
  }
}
