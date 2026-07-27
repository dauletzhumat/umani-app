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
import 'package:mobile/features/transactions/presentation/widgets/transaction_tile.dart';

const _currentCategory = Category(
  id: 'cat-old',
  userId: null,
  name: 'Старая категория',
  icon: 'category',
);
const _pickerCategory = Category(
  id: 'cat-1',
  userId: null,
  name: 'Продукты',
  icon: 'shopping_cart',
);
const _transaction = Transaction(
  id: 'tx-1',
  accountId: 'acc-1',
  categoryId: 'cat-old',
  amount: '1500.00',
  currency: 'KZT',
  type: TransactionType.expense,
  occurredAt: '2026-01-01',
  note: null,
);

class _FakeCategoryRepository implements CategoryRepository {
  @override
  Future<List<Category>> fetchAll() async => const [_pickerCategory];

  @override
  Future<Category> create({
    required String name,
    required String icon,
    String? parentId,
  }) async {
    throw UnimplementedError();
  }
}

class _FakeTransactionRepository implements TransactionRepository {
  String? lastUpdatedId;
  String? lastUpdatedCategoryId;
  bool deleteCalled = false;

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
    throw UnimplementedError();
  }

  @override
  Future<Transaction> update(String id, {String? categoryId}) async {
    lastUpdatedId = id;
    lastUpdatedCategoryId = categoryId;
    return Transaction(
      id: id,
      accountId: _transaction.accountId,
      categoryId: categoryId,
      amount: _transaction.amount,
      currency: _transaction.currency,
      type: _transaction.type,
      occurredAt: _transaction.occurredAt,
      note: _transaction.note,
    );
  }

  @override
  Future<void> delete(String id) async {
    deleteCalled = true;
  }
}

void main() {
  Future<_FakeTransactionRepository> pumpTile(
    WidgetTester tester, {
    ValueChanged<Category>? onCategoryChanged,
    VoidCallback? onDeleted,
  }) async {
    final fakeTransactionRepository = _FakeTransactionRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(
            fakeTransactionRepository,
          ),
          categoryRepositoryProvider.overrideWithValue(
            _FakeCategoryRepository(),
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
          home: Scaffold(
            body: TransactionTile(
              transaction: _transaction,
              category: _currentCategory,
              onCategoryChanged: onCategoryChanged ?? (_) {},
              onDeleted: onDeleted ?? () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return fakeTransactionRepository;
  }

  testWidgets(
    'swiping right opens the category picker inline, without pushing a new screen, '
    'and applies the picked category without dismissing the tile',
    (WidgetTester tester) async {
      Category? changedTo;
      final fakeTransactionRepository = await pumpTile(
        tester,
        onCategoryChanged: (category) => changedTo = category,
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(TransactionTile), findsOneWidget);

      await tester.drag(find.byType(Dismissible), const Offset(500, 0));
      await tester.pumpAndSettle();

      // The picker is a Bottom Sheet overlay, not a pushed route: still a
      // single Scaffold, and the tile stays mounted underneath it.
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(TransactionTile), findsOneWidget);
      expect(find.text('Продукты'), findsOneWidget);

      await tester.tap(find.text('Продукты'));
      await tester.pumpAndSettle();

      expect(changedTo?.id, 'cat-1');
      expect(fakeTransactionRepository.lastUpdatedId, 'tx-1');
      expect(fakeTransactionRepository.lastUpdatedCategoryId, 'cat-1');
      expect(find.byType(TransactionTile), findsOneWidget);
    },
  );

  testWidgets(
    'swiping left asks for confirmation before deleting',
    (WidgetTester tester) async {
      var deleted = false;
      final fakeTransactionRepository = await pumpTile(
        tester,
        onDeleted: () => deleted = true,
      );

      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Удалить транзакцию?'), findsOneWidget);

      await tester.tap(find.text('Удалить'));
      await tester.pumpAndSettle();

      expect(fakeTransactionRepository.deleteCalled, isTrue);
      expect(deleted, isTrue);
    },
  );
}
