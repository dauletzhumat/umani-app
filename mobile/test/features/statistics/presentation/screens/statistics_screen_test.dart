import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/app_localizations.dart';
import 'package:mobile/features/statistics/data/repositories/reports_repository_impl.dart';
import 'package:mobile/features/statistics/domain/entities/report.dart';
import 'package:mobile/features/statistics/domain/repositories/reports_repository.dart';
import 'package:mobile/features/statistics/presentation/screens/statistics_screen.dart';
import 'package:mobile/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:mobile/features/transactions/domain/entities/transaction.dart';
import 'package:mobile/features/transactions/domain/repositories/transaction_repository.dart';

class _FakeReportsRepository implements ReportsRepository {
  @override
  Future<ByCategoryReport> fetchByCategory({required String period}) async {
    return const ByCategoryReport(
      dateFrom: '2026-07-01',
      dateTo: '2026-07-27',
      totalExpense: '10000.00',
      categories: [
        CategoryBreakdown(
          categoryId: 'cat-1',
          categoryName: 'Продукты',
          amount: '6000.00',
          percentage: 60,
        ),
        CategoryBreakdown(
          categoryId: 'cat-2',
          categoryName: 'Транспорт',
          amount: '4000.00',
          percentage: 40,
        ),
      ],
    );
  }

  @override
  Future<ReportsSummary> fetchSummary({required String period}) async {
    // previousPeriodTotalExpense == 0 suppresses the insight line so this
    // test can focus purely on the tap-to-filter behavior.
    return const ReportsSummary(
      totalIncome: '0.00',
      totalExpense: '10000.00',
      previousPeriodTotalExpense: '0.00',
    );
  }
}

class _FakeReportsRepositoryWithGrowth implements ReportsRepository {
  @override
  Future<ByCategoryReport> fetchByCategory({required String period}) async {
    return const ByCategoryReport(
      dateFrom: '2026-07-01',
      dateTo: '2026-07-27',
      totalExpense: '10000.00',
      categories: [
        CategoryBreakdown(
          categoryId: 'cat-1',
          categoryName: 'Продукты',
          amount: '10000.00',
          percentage: 100,
        ),
      ],
    );
  }

  @override
  Future<ReportsSummary> fetchSummary({required String period}) async {
    // 10000 vs 8000 -> +25%, exercising the {value} substitution in
    // statisticsInsightMoreTemplate (a real bug once used {a} while
    // _template only ever replaces {value} — the literal "{a}" leaked
    // into the UI unsubstituted until this test caught it).
    return const ReportsSummary(
      totalIncome: '0.00',
      totalExpense: '10000.00',
      previousPeriodTotalExpense: '8000.00',
    );
  }
}

Transaction _expense({
  required String id,
  required String categoryId,
  required String amount,
}) => Transaction(
  id: id,
  accountId: 'acc-1',
  categoryId: categoryId,
  amount: amount,
  currency: 'KZT',
  type: TransactionType.expense,
  occurredAt: '2026-07-10',
  note: null,
);

class _FakeTransactionRepository implements TransactionRepository {
  @override
  Future<Transaction> create({
    required String accountId,
    String? categoryId,
    required String amount,
    required String currency,
    required TransactionType type,
    String? occurredAt,
    String? note,
    String? source,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TransactionPage> fetchAll({
    String? accountId,
    String? categoryId,
    TransactionType? type,
    String? dateFrom,
    String? dateTo,
    String? cursor,
    int? limit,
  }) async {
    return TransactionPage(
      items: [
        _expense(id: 'tx-1', categoryId: 'cat-1', amount: '6000.00'),
        _expense(id: 'tx-2', categoryId: 'cat-2', amount: '4000.00'),
      ],
      nextCursor: null,
      hasMore: false,
    );
  }

  @override
  Future<Transaction> update(String id, {String? categoryId}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String id) async {}
}

void main() {
  testWidgets(
    'tapping a legend row filters the transaction list to that category, tapping it again clears the filter',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportsRepositoryProvider.overrideWithValue(
              _FakeReportsRepository(),
            ),
            transactionRepositoryProvider.overrideWithValue(
              _FakeTransactionRepository(),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('ru'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const StatisticsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Both categories' transactions are visible before any tap.
      expect(find.text('-6000.00 KZT'), findsOneWidget);
      expect(find.text('-4000.00 KZT'), findsOneWidget);

      // The legend row for "Продукты" renders before its own transaction's
      // list tile of the same name, so .first reliably hits the legend.
      final legendRow = find.text('Продукты').first;
      await tester.ensureVisible(legendRow);
      await tester.pumpAndSettle();
      await tester.tap(legendRow);
      await tester.pumpAndSettle();

      expect(find.text('-6000.00 KZT'), findsOneWidget);
      expect(find.text('-4000.00 KZT'), findsNothing);

      // Tapping the same legend row again toggles the filter back off.
      await tester.tap(legendRow);
      await tester.pumpAndSettle();

      expect(find.text('-6000.00 KZT'), findsOneWidget);
      expect(find.text('-4000.00 KZT'), findsOneWidget);
    },
  );

  testWidgets(
    'the period-comparison insight text substitutes the percent value correctly',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportsRepositoryProvider.overrideWithValue(
              _FakeReportsRepositoryWithGrowth(),
            ),
            transactionRepositoryProvider.overrideWithValue(
              _FakeTransactionRepository(),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('ru'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const StatisticsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('На 25% больше, чем в прошлом периоде'),
        findsOneWidget,
      );
    },
  );
}
