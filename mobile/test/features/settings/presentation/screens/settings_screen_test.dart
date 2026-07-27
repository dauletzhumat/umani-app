import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/localization/app_localizations.dart';
import 'package:mobile/core/localization/locale_provider.dart';
import 'package:mobile/core/network/token_manager.dart';
import 'package:mobile/core/storage/session_storage.dart';
import 'package:mobile/features/settings/data/repositories/user_repository_impl.dart';
import 'package:mobile/features/settings/domain/entities/user_profile.dart';
import 'package:mobile/features/settings/domain/repositories/user_repository.dart';
import 'package:mobile/features/settings/presentation/screens/settings_screen.dart';

class _FakeSessionStorage implements SessionStorage {
  @override
  Future<void> clear() async {}

  @override
  Future<bool> hasSession() async => false;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> saveRefreshToken(String token) async {}
}

TokenManager _fakeTokenManager() {
  return TokenManager(
    refreshDio: Dio(),
    sessionStorage: _FakeSessionStorage(),
    getAccessToken: () => null,
    setAccessToken: (_) {},
    clearAccessToken: () {},
  );
}

class _FakeUserRepository implements UserRepository {
  _FakeUserRepository({this.scheduledPurgeAt = '2026-08-26T00:00:00.000Z'});

  final String scheduledPurgeAt;
  bool deleteAccountCalled = false;

  @override
  Future<UserProfile> fetchProfile() async {
    return const UserProfile(
      id: 'user-1',
      phone: '+77011112233',
      email: null,
      name: 'Dana',
      locale: 'ru',
      defaultCurrency: 'KZT',
    );
  }

  @override
  Future<UserProfile> updateProfile({
    String? name,
    String? defaultCurrency,
  }) async {
    return UserProfile(
      id: 'user-1',
      phone: '+77011112233',
      email: null,
      name: name,
      locale: 'ru',
      defaultCurrency: defaultCurrency ?? 'KZT',
    );
  }

  @override
  Future<String> deleteAccount() async {
    deleteAccountCalled = true;
    return scheduledPurgeAt;
  }
}

/// Mirrors main.dart's App: MaterialApp.locale driven by localeProvider —
/// same shape as language_screen_test.dart's _LocaleAwareApp.
class _LocaleAwareApp extends ConsumerWidget {
  const _LocaleAwareApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SettingsScreen(),
    );
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'selecting a language on Settings applies immediately, without recreating the widget',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userRepositoryProvider.overrideWithValue(_FakeUserRepository()),
          ],
          child: const _LocaleAwareApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Not asserting on the pre-tap title: the test harness's device
      // locale (whatever it resolves to) picks the initial locale, same
      // as LocaleNotifier.build() does for a real first launch — only
      // "Қазақша" itself is locale-invariant (native name in all three
      // locale blocks), which is why it's safe to find and tap directly.
      await tester.tap(find.text('Қазақша'));
      await tester.pumpAndSettle();

      expect(find.text('Баптаулар'), findsOneWidget);
    },
  );

  testWidgets(
    'deleting the account requires explicit confirmation and then shows the actual deletion date',
    (tester) async {
      final userRepository = _FakeUserRepository(
        scheduledPurgeAt: '2026-08-26T00:00:00.000Z',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userRepositoryProvider.overrideWithValue(userRepository),
            tokenManagerProvider.overrideWithValue(_fakeTokenManager()),
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
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // skipOffstage: false — the button is the last item in a ListView,
      // below the fold, so the sliver protocol hasn't laid it out yet and
      // the default finder (skipOffstage: true) can't see it until
      // ensureVisible scrolls there.
      final deleteButton = find.text('Удалить аккаунт', skipOffstage: false);
      await tester.ensureVisible(deleteButton);
      await tester.pumpAndSettle();
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // The dialog itself is the confirmation gate — cancelling must not
      // call through to DELETE /users/me.
      expect(find.text('Удалить аккаунт?'), findsOneWidget);
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect(userRepository.deleteAccountCalled, isFalse);

      await tester.tap(deleteButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Удалить'));
      await tester.pumpAndSettle();

      expect(userRepository.deleteAccountCalled, isTrue);
      expect(find.text('Ваш аккаунт будет полностью удалён 26.08.2026.'), findsOneWidget);
    },
  );
}
