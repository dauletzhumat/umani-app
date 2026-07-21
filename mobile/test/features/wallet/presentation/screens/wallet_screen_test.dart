import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/app_localizations.dart';
import 'package:mobile/features/wallet/data/repositories/account_repository_impl.dart';
import 'package:mobile/features/wallet/domain/entities/account.dart';
import 'package:mobile/features/wallet/domain/repositories/account_repository.dart';
import 'package:mobile/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:mobile/features/wallet/presentation/widgets/account_carousel.dart';

class _FakeAccountRepository implements AccountRepository {
  _FakeAccountRepository(this._accounts);

  final List<Account> _accounts;

  @override
  Future<List<Account>> fetchAll() async => List.unmodifiable(_accounts);

  @override
  Future<Account> update(String id, {String? name, bool? archived}) async {
    throw UnimplementedError();
  }
}

Future<void> pumpWallet(WidgetTester tester, AccountRepository repository) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [accountRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const WalletScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the empty state when there are no accounts', (
    WidgetTester tester,
  ) async {
    await pumpWallet(tester, _FakeAccountRepository(const []));

    expect(find.text('Здесь появятся ваши счета'), findsOneWidget);
    expect(find.text('Добавить счёт'), findsOneWidget);
    expect(find.byType(AccountCarousel), findsNothing);
  });

  testWidgets('the "+ add account" card is always last in the carousel', (
    WidgetTester tester,
  ) async {
    const accounts = [
      Account(
        id: 'a1',
        userId: 'u1',
        type: AccountType.cash,
        name: 'Наличные',
        currency: 'KZT',
        balanceCached: '100.00',
        provider: null,
        archived: false,
      ),
      Account(
        id: 'a2',
        userId: 'u1',
        type: AccountType.bank,
        name: 'Kaspi Gold',
        currency: 'KZT',
        balanceCached: '200.00',
        provider: null,
        archived: false,
      ),
    ];
    await pumpWallet(tester, _FakeAccountRepository(accounts));

    expect(find.byType(AccountCarousel), findsOneWidget);

    final account1Dx = tester.getTopLeft(find.text('Наличные')).dx;
    final account2Dx = tester.getTopLeft(find.text('Kaspi Gold')).dx;
    final addCardDx = tester.getTopLeft(find.text('+ Добавить счёт')).dx;

    expect(addCardDx, greaterThan(account1Dx));
    expect(addCardDx, greaterThan(account2Dx));
  });
}
