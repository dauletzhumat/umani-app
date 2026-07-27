import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/app_localizations.dart';
import 'package:mobile/features/dashboard/presentation/widgets/upcoming_installment_widget.dart';
import 'package:mobile/features/installments/data/repositories/installment_repository_impl.dart';
import 'package:mobile/features/installments/domain/entities/installment.dart';
import 'package:mobile/features/installments/domain/repositories/installment_repository.dart';

class _FakeInstallmentRepository implements InstallmentRepository {
  _FakeInstallmentRepository(this.overview);

  final InstallmentsOverview overview;

  @override
  Future<InstallmentsOverview> fetchAll() async => overview;

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

Future<void> _pumpWidget(
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
        home: const Scaffold(body: UpcomingInstallmentWidget()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders nothing when there are no active installments', (
    tester,
  ) async {
    await _pumpWidget(
      tester,
      const InstallmentsOverview(totalOutstanding: '0.00', installments: []),
    );

    expect(find.byType(Card), findsNothing);
    expect(find.text('Ближайший платёж'), findsNothing);
  });

  testWidgets(
    'renders nothing when every installment is already fully paid off',
    (tester) async {
      await _pumpWidget(
        tester,
        const InstallmentsOverview(
          totalOutstanding: '0.00',
          installments: [
            Installment(
              id: 'i1',
              merchant: 'Technodom',
              totalAmount: '100000.00',
              installmentsCount: 5,
              provider: null,
              nextPayment: null,
            ),
          ],
        ),
      );

      expect(find.byType(Card), findsNothing);
    },
  );

  testWidgets('shows the nearest upcoming payment when one exists', (
    tester,
  ) async {
    await _pumpWidget(
      tester,
      const InstallmentsOverview(
        totalOutstanding: '20000.00',
        installments: [
          Installment(
            id: 'i1',
            merchant: 'Technodom',
            totalAmount: '100000.00',
            installmentsCount: 5,
            provider: null,
            nextPayment: InstallmentNextPayment(
              dueDate: '2026-08-05',
              amount: '20000.00',
            ),
          ),
        ],
      ),
    );

    expect(find.byType(Card), findsOneWidget);
    expect(find.text('Ближайший платёж'), findsOneWidget);
    expect(find.text('Technodom · 20000.00'), findsOneWidget);
  });
}
