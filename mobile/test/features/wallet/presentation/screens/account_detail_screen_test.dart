import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/app_localizations.dart';
import 'package:mobile/features/wallet/data/repositories/account_repository_impl.dart';
import 'package:mobile/features/wallet/domain/entities/account.dart';
import 'package:mobile/features/wallet/domain/repositories/account_repository.dart';
import 'package:mobile/features/wallet/presentation/screens/account_detail_screen.dart';

const _account = Account(
  id: 'a1',
  userId: 'u1',
  type: AccountType.cash,
  name: 'Наличные',
  currency: 'KZT',
  balanceCached: '100.00',
  provider: null,
  archived: false,
);

class _FakeAccountRepository implements AccountRepository {
  @override
  Future<List<Account>> fetchAll() async => const [_account];

  @override
  Future<Account> update(String id, {String? name, bool? archived}) async {
    return _account.copyWith(name: name, archived: archived);
  }
}

void main() {
  testWidgets(
    'shows account name/balance and toggles archive state on tap',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
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
            home: const AccountDetailScreen(account: _account),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Наличные'), findsOneWidget);
      expect(find.text('100.00 KZT'), findsOneWidget);
      expect(find.text('Архивировать счёт'), findsOneWidget);

      await tester.tap(find.text('Архивировать счёт'));
      await tester.pumpAndSettle();

      expect(find.text('Вернуть из архива'), findsOneWidget);
    },
  );
}
