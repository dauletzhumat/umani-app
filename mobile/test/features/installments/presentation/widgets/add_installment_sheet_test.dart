import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/app_localizations.dart';
import 'package:mobile/features/installments/data/repositories/installment_repository_impl.dart';
import 'package:mobile/features/installments/domain/entities/installment.dart';
import 'package:mobile/features/installments/domain/repositories/installment_repository.dart';
import 'package:mobile/features/installments/presentation/widgets/add_installment_sheet.dart';

class _FakeInstallmentRepository implements InstallmentRepository {
  int? lastInstallmentsCount;

  @override
  Future<InstallmentsOverview> fetchAll() async {
    throw UnimplementedError();
  }

  @override
  Future<Installment> create({
    required String merchant,
    required String totalAmount,
    required int installmentsCount,
    required String startDate,
  }) async {
    lastInstallmentsCount = installmentsCount;
    return Installment(
      id: 'i1',
      merchant: merchant,
      totalAmount: totalAmount,
      installmentsCount: installmentsCount,
      provider: null,
      nextPayment: null,
    );
  }
}

void main() {
  Future<_FakeInstallmentRepository> pumpSheet(WidgetTester tester) async {
    final fakeInstallmentRepository = _FakeInstallmentRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          installmentRepositoryProvider.overrideWithValue(
            fakeInstallmentRepository,
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
                      onPressed: () => AddInstallmentSheet.show(context),
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

    return fakeInstallmentRepository;
  }

  FilledButton saveButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton));

  testWidgets(
    'a non-positive number of payments keeps Save disabled',
    (WidgetTester tester) async {
      await pumpSheet(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'Магазин'),
        'Technodom',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Сумма'),
        '120000',
      );
      await tester.pumpAndSettle();

      // No count entered yet — still disabled.
      expect(saveButton(tester).onPressed, isNull);

      await tester.enterText(
        find.widgetWithText(TextField, 'Количество платежей'),
        '0',
      );
      await tester.pumpAndSettle();
      expect(saveButton(tester).onPressed, isNull);

      await tester.enterText(
        find.widgetWithText(TextField, 'Количество платежей'),
        '-3',
      );
      await tester.pumpAndSettle();
      expect(saveButton(tester).onPressed, isNull);

      await tester.enterText(
        find.widgetWithText(TextField, 'Количество платежей'),
        '12',
      );
      await tester.pumpAndSettle();
      expect(saveButton(tester).onPressed, isNotNull);
    },
  );
}
