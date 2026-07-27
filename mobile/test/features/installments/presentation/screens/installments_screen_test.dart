import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/app_localizations.dart';
import 'package:mobile/features/installments/data/repositories/installment_repository_impl.dart';
import 'package:mobile/features/installments/domain/entities/installment.dart';
import 'package:mobile/features/installments/domain/repositories/installment_repository.dart';
import 'package:mobile/features/installments/presentation/screens/installments_screen.dart';

class _FakeInstallmentRepository implements InstallmentRepository {
  _FakeInstallmentRepository(this.overview);

  final InstallmentsOverview overview;

  @override
  Future<InstallmentsOverview> fetchAll() async => overview;
}

Future<void> _pumpScreen(
  WidgetTester tester,
  InstallmentsOverview overview,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        installmentRepositoryProvider.overrideWithValue(
          _FakeInstallmentRepository(overview),
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
        home: const InstallmentsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'shows the server-aggregated total outstanding debt across all active installments',
    (tester) async {
      await _pumpScreen(
        tester,
        const InstallmentsOverview(
          totalOutstanding: '185000.00',
          installments: [
            Installment(
              id: 'i1',
              merchant: 'Technodom',
              totalAmount: '240000.00',
              installmentsCount: 12,
              provider: 'Kaspi Rassrochka',
              nextPayment: InstallmentNextPayment(
                dueDate: '2026-07-18',
                amount: '20000.00',
              ),
            ),
            Installment(
              id: 'i2',
              merchant: 'Sulpak',
              totalAmount: '60000.00',
              installmentsCount: 6,
              provider: null,
              nextPayment: null,
            ),
          ],
        ),
      );

      expect(find.text('185000.00'), findsOneWidget);
      expect(find.text('Technodom'), findsOneWidget);
      expect(find.text('Sulpak'), findsOneWidget);
      expect(find.text('Нет предстоящих платежей'), findsOneWidget);
    },
  );

  testWidgets('shows the empty state when there are no active installments', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      const InstallmentsOverview(totalOutstanding: '0.00', installments: []),
    );

    expect(find.text('Нет активных рассрочек'), findsOneWidget);
    expect(find.byType(Card), findsNothing);
  });
}
