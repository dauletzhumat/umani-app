import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/app_localizations.dart';
import 'package:mobile/features/categories/data/repositories/category_repository_impl.dart';
import 'package:mobile/features/categories/domain/entities/category.dart';
import 'package:mobile/features/categories/domain/repositories/category_repository.dart';
import 'package:mobile/features/transactions/data/datasources/ocr_remote_datasource.dart';
import 'package:mobile/features/transactions/presentation/screens/receipt_preview_screen.dart';
import 'package:mobile/features/wallet/data/repositories/account_repository_impl.dart';
import 'package:mobile/features/wallet/domain/entities/account.dart';
import 'package:mobile/features/wallet/domain/repositories/account_repository.dart';

class _FakeCategoryRepository implements CategoryRepository {
  @override
  Future<List<Category>> fetchAll() async => const [
    Category(id: 'cat-1', userId: null, name: 'Продукты', icon: 'shopping_cart'),
  ];

  @override
  Future<Category> create({
    required String name,
    required String icon,
    String? parentId,
  }) async {
    throw UnimplementedError();
  }
}

class _FakeAccountRepository implements AccountRepository {
  @override
  Future<List<Account>> fetchAll() async => const [
    Account(
      id: 'acc-1',
      userId: 'u1',
      type: AccountType.cash,
      name: 'Наличные',
      currency: 'KZT',
      balanceCached: '1000.00',
      provider: null,
      archived: false,
    ),
  ];

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

const _scanResult = ReceiptScanResult(
  receiptScanId: 'scan-1',
  status: 'processed',
  draftTransaction: DraftTransaction(
    merchant: 'Magnum',
    amount: '12400.00',
    currency: 'KZT',
    suggestedCategoryId: 'cat-1',
    lineItems: [DraftLineItem(name: 'Молоко 2.5%', price: '650.00')],
  ),
);

void main() {
  testWidgets(
    'shows editable amount/category/line-item fields from a mocked OCR draft',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoryRepositoryProvider.overrideWithValue(
              _FakeCategoryRepository(),
            ),
            accountRepositoryProvider.overrideWithValue(
              _FakeAccountRepository(),
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
            home: const ReceiptPreviewScreen(scanResult: _scanResult),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Amount is editable and pre-filled from the draft.
      final amountField = tester.widget<TextField>(
        find.widgetWithText(TextField, '12400.00'),
      );
      expect(amountField.enabled ?? true, isTrue);

      // Category defaulted from suggestedCategoryId, resolved by name.
      expect(find.text('Продукты'), findsOneWidget);

      // Line item name/price are editable and pre-filled.
      expect(
        find.widgetWithText(TextField, 'Молоко 2.5%'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextField, '650.00'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, '12400.00'),
        '13000.00',
      );
      await tester.pump();
      expect(find.widgetWithText(TextField, '13000.00'), findsOneWidget);
    },
  );
}
