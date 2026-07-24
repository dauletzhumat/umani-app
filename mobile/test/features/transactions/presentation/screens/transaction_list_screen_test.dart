import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/app_localizations.dart';
import 'package:mobile/features/categories/data/repositories/category_repository_impl.dart';
import 'package:mobile/features/categories/domain/entities/category.dart';
import 'package:mobile/features/categories/domain/repositories/category_repository.dart';
import 'package:mobile/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:mobile/features/transactions/domain/entities/transaction.dart';
import 'package:mobile/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:mobile/features/transactions/presentation/screens/transaction_list_screen.dart';
import 'package:mobile/features/wallet/data/repositories/account_repository_impl.dart';
import 'package:mobile/features/wallet/domain/entities/account.dart';
import 'package:mobile/features/wallet/domain/repositories/account_repository.dart';

class _EmptyAccountRepository implements AccountRepository {
  @override
  Future<List<Account>> fetchAll() async => const [];

  @override
  Future<Account> create({
    required AccountType type,
    required String name,
    required String currency,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Account> update(String id, {String? name, bool? archived}) async {
    throw UnimplementedError();
  }
}

class _EmptyCategoryRepository implements CategoryRepository {
  @override
  Future<List<Category>> fetchAll() async => const [];

  @override
  Future<Category> create({
    required String name,
    required String icon,
    String? parentId,
  }) async {
    throw UnimplementedError();
  }
}

List<Transaction> _page(int count, int offset) => List.generate(
  count,
  (i) => Transaction(
    id: 'tx-${offset + i}',
    accountId: 'acc-1',
    categoryId: null,
    amount: '100.00',
    currency: 'KZT',
    type: TransactionType.expense,
    occurredAt: '2026-01-01',
    note: null,
  ),
);

class _PagedTransactionRepository implements TransactionRepository {
  final List<String?> cursorsRequested = [];

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
  }) async {
    cursorsRequested.add(cursor);
    if (cursor == null) {
      return TransactionPage(
        items: _page(30, 0),
        nextCursor: 'cursor-page-2',
        hasMore: true,
      );
    }
    return TransactionPage(items: _page(5, 30), nextCursor: null, hasMore: false);
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
    'scrolling to the end of the list loads the next page using the cursor from the previous page',
    (WidgetTester tester) async {
      final fakeTransactionRepository = _PagedTransactionRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(
              fakeTransactionRepository,
            ),
            accountRepositoryProvider.overrideWithValue(
              _EmptyAccountRepository(),
            ),
            categoryRepositoryProvider.overrideWithValue(
              _EmptyCategoryRepository(),
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
            home: const TransactionListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(fakeTransactionRepository.cursorsRequested, [null]);

      await tester.fling(find.byType(ListView), const Offset(0, -3000), 3000);
      await tester.pumpAndSettle();

      expect(fakeTransactionRepository.cursorsRequested, [null, 'cursor-page-2']);
    },
  );
}
