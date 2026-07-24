import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/app_localizations.dart';
import 'package:mobile/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:mobile/features/transactions/domain/entities/transaction.dart';
import 'package:mobile/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:mobile/features/transactions/presentation/screens/manual_entry_screen.dart';
import 'package:mobile/features/wallet/data/repositories/account_repository_impl.dart';
import 'package:mobile/features/wallet/domain/entities/account.dart';
import 'package:mobile/features/wallet/domain/repositories/account_repository.dart';

const _account = Account(
  id: 'acc-1',
  userId: 'u1',
  type: AccountType.cash,
  name: 'Наличные',
  currency: 'KZT',
  balanceCached: '1000.00',
  provider: null,
  archived: false,
);

class _FakeAccountRepository implements AccountRepository {
  @override
  Future<List<Account>> fetchAll() async => const [_account];

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

class _FakeTransactionRepository implements TransactionRepository {
  String? lastAmount;

  @override
  Future<Transaction> create({
    required String accountId,
    String? categoryId,
    required String amount,
    required String currency,
    required TransactionType type,
    String? occurredAt,
    String? note,
  }) async {
    lastAmount = amount;
    return Transaction(
      id: 'tx-1',
      accountId: accountId,
      categoryId: categoryId,
      amount: amount,
      currency: currency,
      type: type,
      occurredAt: occurredAt ?? '2026-01-01',
      note: note,
    );
  }
}

void main() {
  Future<_FakeTransactionRepository> pumpSheet(WidgetTester tester) async {
    final fakeTransactionRepository = _FakeTransactionRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountRepositoryProvider.overrideWithValue(
            _FakeAccountRepository(),
          ),
          transactionRepositoryProvider.overrideWithValue(
            fakeTransactionRepository,
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
          home: Builder(
            builder:
                (context) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () => ManualEntryScreen.show(context),
                      child: const Text('open'),
                    ),
                  ),
                ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    return fakeTransactionRepository;
  }

  FilledButton saveButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton));

  testWidgets(
    'an empty or zero amount keeps the Save button disabled',
    (WidgetTester tester) async {
      await pumpSheet(tester);

      expect(saveButton(tester).onPressed, isNull);

      await tester.enterText(
        find.widgetWithText(TextField, 'Сумма'),
        '0',
      );
      await tester.pumpAndSettle();

      expect(saveButton(tester).onPressed, isNull);
    },
  );

  testWidgets(
    'a positive amount enables Save; saving closes the sheet and shows a confirmation toast',
    (WidgetTester tester) async {
      final fakeTransactionRepository = await pumpSheet(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'Сумма'),
        '1500',
      );
      await tester.pumpAndSettle();

      expect(saveButton(tester).onPressed, isNotNull);

      await tester.ensureVisible(find.byType(FilledButton));
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(fakeTransactionRepository.lastAmount, '1500');
      expect(find.text('Новая транзакция'), findsNothing);
      expect(find.text('Транзакция сохранена'), findsOneWidget);
    },
  );
}
