import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/app_localizations.dart';
import 'package:mobile/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:mobile/features/budgets/domain/entities/budget.dart';
import 'package:mobile/features/budgets/domain/repositories/budget_repository.dart';
import 'package:mobile/features/categories/data/repositories/category_repository_impl.dart';
import 'package:mobile/features/categories/domain/entities/category.dart';
import 'package:mobile/features/categories/domain/repositories/category_repository.dart';
import 'package:mobile/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:mobile/features/installments/data/repositories/installment_repository_impl.dart';
import 'package:mobile/features/installments/domain/entities/installment.dart';
import 'package:mobile/features/installments/domain/repositories/installment_repository.dart';
import 'package:mobile/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:mobile/features/transactions/domain/entities/transaction.dart';
import 'package:mobile/features/transactions/domain/repositories/transaction_repository.dart';

class _EmptyBudgetRepository implements BudgetRepository {
  @override
  Future<List<Budget>> fetchAll() async => const [];

  @override
  Future<Budget> create({
    required String categoryId,
    required String amountLimit,
    required BudgetPeriod period,
    required String startDate,
  }) async {
    throw UnimplementedError();
  }
}

class _EmptyInstallmentRepository implements InstallmentRepository {
  @override
  Future<InstallmentsOverview> fetchAll() async =>
      const InstallmentsOverview(totalOutstanding: '0.00', installments: []);

  @override
  Future<Installment> create({
    required String merchant,
    required String totalAmount,
    required int installmentsCount,
    required String startDate,
  }) async {
    throw UnimplementedError();
  }
}

const _groceries = Category(
  id: 'cat-1',
  userId: null,
  name: 'Продукты',
  icon: 'shopping_cart',
);

class _FakeCategoryRepository implements CategoryRepository {
  @override
  Future<List<Category>> fetchAll() async => const [_groceries];

  @override
  Future<Category> create({
    required String name,
    required String icon,
    String? parentId,
  }) async {
    throw UnimplementedError();
  }
}

Transaction _expense({
  required String id,
  required String amount,
  String? categoryId,
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
    if (type == TransactionType.expense) {
      // Monthly-spending query (BalanceWidget): 15000 + 5000 = 20000.00.
      return TransactionPage(
        items: [
          _expense(id: 'tx-1', amount: '15000.00', categoryId: 'cat-1'),
          _expense(id: 'tx-2', amount: '5000.00', categoryId: 'cat-1'),
        ],
        nextCursor: null,
        hasMore: false,
      );
    }
    // Recent-transactions query (RecentTransactionsWidget).
    return TransactionPage(
      items: [
        _expense(id: 'tx-3', amount: '12400.00', categoryId: 'cat-1'),
        _expense(id: 'tx-4', amount: '3000.00', categoryId: null),
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

class _EmptyTransactionRepository implements TransactionRepository {
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
  }) async => const TransactionPage(items: [], nextCursor: null, hasMore: false);

  @override
  Future<Transaction> update(String id, {String? categoryId}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String id) async {}
}

class _CountingTransactionRepository implements TransactionRepository {
  int fetchAllCallCount = 0;

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
    fetchAllCallCount++;
    return const TransactionPage(items: [], nextCursor: null, hasMore: false);
  }

  @override
  Future<Transaction> update(String id, {String? categoryId}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String id) async {}
}

class _CountingBudgetRepository implements BudgetRepository {
  int fetchAllCallCount = 0;

  @override
  Future<List<Budget>> fetchAll() async {
    fetchAllCallCount++;
    return const [];
  }

  @override
  Future<Budget> create({
    required String categoryId,
    required String amountLimit,
    required BudgetPeriod period,
    required String startDate,
  }) async {
    throw UnimplementedError();
  }
}

class _CountingInstallmentRepository implements InstallmentRepository {
  int fetchAllCallCount = 0;

  @override
  Future<InstallmentsOverview> fetchAll() async {
    fetchAllCallCount++;
    return const InstallmentsOverview(totalOutstanding: '0.00', installments: []);
  }

  @override
  Future<Installment> create({
    required String merchant,
    required String totalAmount,
    required int installmentsCount,
    required String startDate,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  testWidgets(
    'BalanceWidget and RecentTransactionsWidget render correctly on mocked provider data',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(
              _FakeTransactionRepository(),
            ),
            categoryRepositoryProvider.overrideWithValue(
              _FakeCategoryRepository(),
            ),
            budgetRepositoryProvider.overrideWithValue(
              _EmptyBudgetRepository(),
            ),
            installmentRepositoryProvider.overrideWithValue(
              _EmptyInstallmentRepository(),
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
            home: const DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // BalanceWidget: 15000.00 + 5000.00 from the monthly-spending query.
      expect(find.text('20000.00'), findsOneWidget);

      // RecentTransactionsWidget: both recent rows, one resolved to its
      // category name and one falling back to "no category".
      expect(find.text('Продукты'), findsOneWidget);
      expect(find.text('Без категории'), findsOneWidget);
      expect(find.text('-12400.00 KZT'), findsOneWidget);
      expect(find.text('-3000.00 KZT'), findsOneWidget);
    },
  );

  testWidgets(
    'a user with no data sees a meaningful Empty-state with CTAs, not a blank screen',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(
              _EmptyTransactionRepository(),
            ),
            categoryRepositoryProvider.overrideWithValue(
              _FakeCategoryRepository(),
            ),
            budgetRepositoryProvider.overrideWithValue(
              _EmptyBudgetRepository(),
            ),
            installmentRepositoryProvider.overrideWithValue(
              _EmptyInstallmentRepository(),
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
            home: const DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Создать первый бюджет'), findsOneWidget);
      expect(find.text('Добавить первую операцию'), findsOneWidget);
    },
  );

  testWidgets(
    'pull-to-refresh re-fetches all four dashboard data sources',
    (tester) async {
      final transactionRepository = _CountingTransactionRepository();
      final budgetRepository = _CountingBudgetRepository();
      final installmentRepository = _CountingInstallmentRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(
              transactionRepository,
            ),
            categoryRepositoryProvider.overrideWithValue(
              _FakeCategoryRepository(),
            ),
            budgetRepositoryProvider.overrideWithValue(budgetRepository),
            installmentRepositoryProvider.overrideWithValue(
              installmentRepository,
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
            home: const DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final transactionCallsBefore = transactionRepository.fetchAllCallCount;
      final budgetCallsBefore = budgetRepository.fetchAllCallCount;
      final installmentCallsBefore = installmentRepository.fetchAllCallCount;

      await tester.fling(
        find.byType(SingleChildScrollView),
        const Offset(0, 300),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(
        transactionRepository.fetchAllCallCount,
        greaterThan(transactionCallsBefore),
      );
      expect(
        budgetRepository.fetchAllCallCount,
        greaterThan(budgetCallsBefore),
      );
      expect(
        installmentRepository.fetchAllCallCount,
        greaterThan(installmentCallsBefore),
      );
    },
  );
}
