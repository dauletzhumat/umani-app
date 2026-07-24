import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/app_localizations.dart';
import 'package:mobile/features/budgets/domain/entities/budget.dart';
import 'package:mobile/features/budgets/presentation/widgets/budget_card.dart';

Budget _budgetWithProgress(int progressPercent) => Budget(
  id: 'b1',
  categoryId: 'c1',
  categoryName: 'Продукты',
  amountLimit: '10000.00',
  period: BudgetPeriod.monthly,
  startDate: '2026-07-01',
  spentAmount: '0.00',
  remainingAmount: '10000.00',
  progressPercent: progressPercent,
);

Future<Color?> _pumpAndGetIndicatorColor(
  WidgetTester tester,
  int progressPercent,
) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ru'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: BudgetCard(budget: _budgetWithProgress(progressPercent)),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return tester.widget<LinearProgressIndicator>(
    find.byType(LinearProgressIndicator),
  ).color;
}

void main() {
  testWidgets('indicator is green below 70%', (tester) async {
    final color = await _pumpAndGetIndicatorColor(tester, 50);
    expect(color, Colors.green);
  });

  testWidgets('indicator is yellow between 70% and 99%', (tester) async {
    final color = await _pumpAndGetIndicatorColor(tester, 85);
    expect(color, Colors.amber);
  });

  testWidgets('indicator is red at 100% and above', (tester) async {
    final atLimit = await _pumpAndGetIndicatorColor(tester, 100);
    expect(atLimit, Colors.red);

    final overspent = await _pumpAndGetIndicatorColor(tester, 130);
    expect(overspent, Colors.red);
  });
}
