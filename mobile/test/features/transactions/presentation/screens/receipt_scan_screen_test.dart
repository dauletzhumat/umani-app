import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/app_localizations.dart';
import 'package:mobile/features/transactions/data/services/receipt_capture_service.dart';
import 'package:mobile/features/transactions/presentation/screens/receipt_scan_screen.dart';

class _PermissionDeniedCaptureService implements ReceiptCaptureService {
  @override
  Future<ReceiptCaptureResult> captureReceipt() async {
    return const ReceiptCaptureResult(ReceiptCaptureOutcome.permissionDenied);
  }
}

void main() {
  testWidgets(
    'a denied camera permission offers a manual-entry fallback instead of a blank screen',
    (WidgetTester tester) async {
      var fallbackTapped = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            receiptCaptureServiceProvider.overrideWithValue(
              _PermissionDeniedCaptureService(),
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
            home: ReceiptScanScreen(
              onManualEntryFallback: () => fallbackTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Снять фото'));
      await tester.pumpAndSettle();

      expect(
        find.text('Нет доступа к камере. Вы можете ввести транзакцию вручную.'),
        findsOneWidget,
      );
      expect(find.text('Ввести вручную'), findsOneWidget);

      await tester.tap(find.text('Ввести вручную'));
      await tester.pump();

      expect(fallbackTapped, isTrue);
    },
  );
}
