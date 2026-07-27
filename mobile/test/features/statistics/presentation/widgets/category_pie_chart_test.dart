import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/app_localizations.dart';
import 'package:mobile/features/statistics/domain/entities/report.dart';
import 'package:mobile/features/statistics/presentation/widgets/category_pie_chart.dart';

// docs/09_Design_System.md §11's fixed categorical palette (light variant),
// hardcoded independently of category_pie_chart.dart's own _palette so this
// test actually pins down the design-system contract rather than just
// mirroring the implementation.
const _expectedLightPalette = [
  Color(0xFF2A78D6),
  Color(0xFF008300),
  Color(0xFFE87BA4),
  Color(0xFFEDA100),
  Color(0xFF1BAF7A),
  Color(0xFFEB6834),
  Color(0xFF4A3AA7),
  Color(0xFFE34948),
];

List<CategoryBreakdown> _categories(int count) => [
  for (var i = 0; i < count; i++)
    CategoryBreakdown(
      categoryId: 'cat-$i',
      categoryName: 'Категория $i',
      amount: '100.00',
      percentage: (100 / count).round(),
    ),
];

List<Color> _legendSwatchColors(WidgetTester tester) {
  final containers = tester
      .widgetList<Container>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration! as BoxDecoration).shape ==
                  BoxShape.circle,
        ),
      )
      .toList();
  return [
    for (final container in containers)
      (container.decoration! as BoxDecoration).color!,
  ];
}

Future<void> _pumpChart(WidgetTester tester, List<ChartSlice> slices) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: Brightness.light),
      locale: const Locale('ru'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: SingleChildScrollView(
          child: CategoryPieChart(
            slices: slices,
            isSelected: (_) => false,
            onSliceTap: (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'legend swatches follow the fixed 09_Design_System.md §11 palette order',
    (tester) async {
      final slices = prepareChartSlices(_categories(8), 'Другое');

      await _pumpChart(tester, slices);
      await tester.pumpAndSettle();

      expect(_legendSwatchColors(tester), _expectedLightPalette);
    },
  );

  testWidgets(
    'more than 8 categories collapse into "Другое" using the 8th slot, never a 9th color',
    (tester) async {
      final slices = prepareChartSlices(_categories(11), 'Другое');

      expect(slices.length, 8);
      expect(slices.last.isOther, isTrue);

      await _pumpChart(tester, slices);
      await tester.pumpAndSettle();

      expect(_legendSwatchColors(tester), _expectedLightPalette);
    },
  );
}
