import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/app_localizations.dart';
import 'package:mobile/features/transactions/presentation/widgets/add_transaction_sheet.dart';

void main() {
  Future<void> pumpHost(
    WidgetTester tester, {
    required VoidCallback onManualTap,
    required VoidCallback onPhotoTap,
    required VoidCallback onTemplateTap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
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
                    onPressed:
                        () => AddTransactionSheet.show(
                          context,
                          onManualTap: onManualTap,
                          onPhotoTap: onPhotoTap,
                          onTemplateTap: onTemplateTap,
                        ),
                    child: const Text('open'),
                  ),
                ),
              ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    '"Вручную" closes the sheet and calls onManualTap only',
    (WidgetTester tester) async {
      var manualTapped = false;
      var photoTapped = false;
      var templateTapped = false;

      await pumpHost(
        tester,
        onManualTap: () => manualTapped = true,
        onPhotoTap: () => photoTapped = true,
        onTemplateTap: () => templateTapped = true,
      );

      expect(find.text('Добавить транзакцию'), findsOneWidget);

      await tester.tap(find.text('Вручную'));
      await tester.pumpAndSettle();

      expect(manualTapped, isTrue);
      expect(photoTapped, isFalse);
      expect(templateTapped, isFalse);
      expect(find.text('Добавить транзакцию'), findsNothing);
    },
  );

  testWidgets(
    '"Фото чека" closes the sheet and calls onPhotoTap only',
    (WidgetTester tester) async {
      var manualTapped = false;
      var photoTapped = false;
      var templateTapped = false;

      await pumpHost(
        tester,
        onManualTap: () => manualTapped = true,
        onPhotoTap: () => photoTapped = true,
        onTemplateTap: () => templateTapped = true,
      );

      await tester.tap(find.text('Фото чека'));
      await tester.pumpAndSettle();

      expect(photoTapped, isTrue);
      expect(manualTapped, isFalse);
      expect(templateTapped, isFalse);
      expect(find.text('Добавить транзакцию'), findsNothing);
    },
  );

  testWidgets(
    '"Из шаблона" closes the sheet and calls onTemplateTap only',
    (WidgetTester tester) async {
      var manualTapped = false;
      var photoTapped = false;
      var templateTapped = false;

      await pumpHost(
        tester,
        onManualTap: () => manualTapped = true,
        onPhotoTap: () => photoTapped = true,
        onTemplateTap: () => templateTapped = true,
      );

      await tester.tap(find.text('Из шаблона'));
      await tester.pumpAndSettle();

      expect(templateTapped, isTrue);
      expect(manualTapped, isFalse);
      expect(photoTapped, isFalse);
      expect(find.text('Добавить транзакцию'), findsNothing);
    },
  );
}
