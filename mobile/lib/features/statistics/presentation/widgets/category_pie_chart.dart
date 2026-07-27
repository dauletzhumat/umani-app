import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/report.dart';

/// docs/09_Design_System.md §11's fixed categorical palette — never
/// reordered, never cycled. Light/dark variants per slot.
class _PaletteSlot {
  const _PaletteSlot(this.light, this.dark);
  final Color light;
  final Color dark;
}

const _palette = <_PaletteSlot>[
  _PaletteSlot(Color(0xFF2A78D6), Color(0xFF3987E5)), // blue
  _PaletteSlot(Color(0xFF008300), Color(0xFF008300)), // green
  _PaletteSlot(Color(0xFFE87BA4), Color(0xFFD55181)), // magenta
  _PaletteSlot(Color(0xFFEDA100), Color(0xFFC98500)), // yellow
  _PaletteSlot(Color(0xFF1BAF7A), Color(0xFF199E70)), // aqua
  _PaletteSlot(Color(0xFFEB6834), Color(0xFFD95926)), // orange
  _PaletteSlot(Color(0xFF4A3AA7), Color(0xFF9085E9)), // violet
  _PaletteSlot(Color(0xFFE34948), Color(0xFFE66767)), // red
];

Color paletteColorAt(int index, Brightness brightness) {
  final slot = _palette[index];
  return brightness == Brightness.dark ? slot.dark : slot.light;
}

/// A single visible slice — either a real category or the synthetic
/// "Другое" bucket (docs/09_Design_System.md §11: more than 8 spending
/// categories collapse into one "Other" slot rather than generating a
/// 9th color). "Другое" has no single categoryId to filter by, so it
/// isn't tap-filterable ([isOther]); "Без категории" is a real,
/// filterable slice with categoryId == null.
class ChartSlice {
  const ChartSlice({
    required this.label,
    required this.amount,
    required this.percentage,
    this.categoryId,
    this.isOther = false,
  });

  final String label;
  final String amount;
  final int percentage;
  final String? categoryId;
  final bool isOther;
}

/// Caps the visible slices at 8, merging the tail into "Другое"
/// (docs/09_Design_System.md §11). Assumes [categories] is already
/// sorted by amount descending (docs/08_API.md §23's contract).
List<ChartSlice> prepareChartSlices(
  List<CategoryBreakdown> categories,
  String otherLabel,
) {
  if (categories.length <= _palette.length) {
    return categories
        .map(
          (c) => ChartSlice(
            label: c.categoryName,
            amount: c.amount,
            percentage: c.percentage,
            categoryId: c.categoryId,
          ),
        )
        .toList();
  }

  final head = categories.take(_palette.length - 1);
  final tail = categories.skip(_palette.length - 1);

  final otherAmount = tail.fold<double>(
    0,
    (sum, c) => sum + double.parse(c.amount),
  );
  final otherPercentage = tail.fold<int>(0, (sum, c) => sum + c.percentage);

  return [
    ...head.map(
      (c) => ChartSlice(
        label: c.categoryName,
        amount: c.amount,
        percentage: c.percentage,
        categoryId: c.categoryId,
      ),
    ),
    ChartSlice(
      label: otherLabel,
      amount: otherAmount.toStringAsFixed(2),
      percentage: otherPercentage,
      isOther: true,
    ),
  ];
}

class CategoryPieChart extends StatelessWidget {
  const CategoryPieChart({
    super.key,
    required this.slices,
    required this.isSelected,
    required this.onSliceTap,
  });

  final List<ChartSlice> slices;

  /// A callback rather than a bare categoryId — "no slice selected" and
  /// "the 'Без категории' slice (categoryId == null) is selected" would
  /// otherwise be indistinguishable, since both have a null categoryId.
  /// The caller's own selection state knows which one it is.
  final bool Function(ChartSlice slice) isSelected;
  final void Function(ChartSlice slice) onSliceTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brightness = Theme.of(context).brightness;

    if (slices.isEmpty) {
      return Center(child: Text(l10n.statisticsEmptyMessage));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: CustomPaint(
            painter: _PieChartPainter(slices: slices, brightness: brightness),
          ),
        ),
        const SizedBox(height: 16),
        // The legend rows are the primary interactive surface for
        // "tap a sector" — precise pixel/angle hit-testing on the
        // canvas would be fragile to drive from a widget test.
        for (var i = 0; i < slices.length; i++)
          _LegendRow(
            slice: slices[i],
            color: paletteColorAt(i, brightness),
            selected: isSelected(slices[i]),
            onTap: () => onSliceTap(slices[i]),
          ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.slice,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final ChartSlice slice;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: slice.isOther ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                slice.label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Text('${slice.percentage}%'),
          ],
        ),
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  _PieChartPainter({required this.slices, required this.brightness});

  final List<ChartSlice> slices;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(
      0,
      (sum, slice) => sum + double.parse(slice.amount),
    );
    if (total <= 0) return;

    final rect = Offset.zero & size;
    var startAngle = -math.pi / 2;

    for (var i = 0; i < slices.length; i++) {
      final sweep = (double.parse(slices[i].amount) / total) * 2 * math.pi;
      final paint =
          Paint()
            ..style = PaintingStyle.fill
            ..color = paletteColorAt(i, brightness);
      canvas.drawArc(rect, startAngle, sweep, true, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) =>
      oldDelegate.slices != slices || oldDelegate.brightness != brightness;
}
