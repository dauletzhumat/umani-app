import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/app_localizations.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:mobile/features/budgets/domain/entities/budget.dart';
import 'package:mobile/features/budgets/domain/repositories/budget_repository.dart';
import 'package:mobile/features/budgets/presentation/widgets/create_budget_sheet.dart';
import 'package:mobile/features/categories/data/repositories/category_repository_impl.dart';
import 'package:mobile/features/categories/domain/entities/category.dart';
import 'package:mobile/features/categories/domain/repositories/category_repository.dart';

const _groceries = Category(
  id: 'cat-1',
  userId: null,
  name: 'Продукты',
  icon: 'shopping_cart',
);

class _FakeCategoryRepository implements CategoryRepository {
  @override
  Future<List<Category>> fetchAll() async => const [_groceries];

  @override
  Future<Category> create({
    required String name,
    required String icon,
    String? parentId,
  }) async {
    throw UnimplementedError();
  }
}

class _FakeBudgetRepository implements BudgetRepository {
  _FakeBudgetRepository({this.errorToThrow});

  final ApiException? errorToThrow;
  String? lastAmountLimit;

  @override
  Future<List<Budget>> fetchAll() async => const [];

  @override
  Future<Budget> create({
    required String categoryId,
    required String amountLimit,
    required BudgetPeriod period,
    required String startDate,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;

    lastAmountLimit = amountLimit;
    return Budget(
      id: 'budget-1',
      categoryId: categoryId,
      categoryName: _groceries.name,
      amountLimit: amountLimit,
      period: period,
      startDate: startDate,
      spentAmount: '0.00',
      remainingAmount: amountLimit,
      progressPercent: 0,
    );
  }
}

void main() {
  Future<_FakeBudgetRepository> pumpSheet(
    WidgetTester tester, {
    ApiException? errorToThrow,
  }) async {
    final fakeBudgetRepository = _FakeBudgetRepository(
      errorToThrow: errorToThrow,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          budgetRepositoryProvider.overrideWithValue(fakeBudgetRepository),
          categoryRepositoryProvider.overrideWithValue(
            _FakeCategoryRepository(),
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
                      onPressed: () => CreateBudgetSheet.show(context),
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

    return fakeBudgetRepository;
  }

  Future<void> pickCategory(WidgetTester tester) async {
    await tester.tap(find.text('Выберите категорию'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Продукты').last);
    await tester.pumpAndSettle();
  }

  FilledButton saveButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton));

  testWidgets('a limit of 0 or less keeps Save disabled', (tester) async {
    await pumpSheet(tester);
    await pickCategory(tester);

    expect(saveButton(tester).onPressed, isNull);

    await tester.enterText(find.widgetWithText(TextField, 'Лимит'), '0');
    await tester.pumpAndSettle();
    expect(saveButton(tester).onPressed, isNull);

    await tester.enterText(find.widgetWithText(TextField, 'Лимит'), '-500');
    await tester.pumpAndSettle();
    expect(saveButton(tester).onPressed, isNull);

    await tester.enterText(find.widgetWithText(TextField, 'Лимит'), '5000');
    await tester.pumpAndSettle();
    expect(saveButton(tester).onPressed, isNotNull);
  });

  testWidgets(
    'a 409 conflict shows the readable server message, not the raw error code',
    (tester) async {
      await pumpSheet(
        tester,
        errorToThrow: const ApiException(
          code: 'CONFLICT',
          message: 'A budget for this category/period already exists',
        ),
      );
      await pickCategory(tester);

      await tester.enterText(find.widgetWithText(TextField, 'Лимит'), '5000');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byType(FilledButton));
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(
        find.text('A budget for this category/period already exists'),
        findsOneWidget,
      );
      expect(find.text('CONFLICT'), findsNothing);
    },
  );
}
