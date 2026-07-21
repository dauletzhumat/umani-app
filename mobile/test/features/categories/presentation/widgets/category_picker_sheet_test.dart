import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/app_localizations.dart';
import 'package:mobile/features/categories/data/repositories/category_repository_impl.dart';
import 'package:mobile/features/categories/domain/entities/category.dart';
import 'package:mobile/features/categories/domain/repositories/category_repository.dart';
import 'package:mobile/features/categories/presentation/widgets/category_picker_sheet.dart';

class _FakeCategoryRepository implements CategoryRepository {
  final List<Category> _categories = [
    const Category(
      id: 'system-1',
      userId: null,
      name: 'Продукты',
      icon: 'shopping_cart',
    ),
    const Category(
      id: 'custom-1',
      userId: 'user-1',
      name: 'Хобби',
      icon: 'category',
    ),
  ];

  @override
  Future<List<Category>> fetchAll() async => List.unmodifiable(_categories);

  @override
  Future<Category> create({
    required String name,
    required String icon,
    String? parentId,
  }) async {
    final created = Category(
      id: 'created-${_categories.length}',
      userId: 'user-1',
      name: name,
      icon: icon,
      parentId: parentId,
    );
    _categories.add(created);
    return created;
  }
}

void main() {
  Future<void> pumpSheet(WidgetTester tester, CategoryRepository repository) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [categoryRepositoryProvider.overrideWithValue(repository)],
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
                      onPressed: () => CategoryPickerSheet.show(context),
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
  }

  testWidgets(
    'shows system and custom categories for the user',
    (WidgetTester tester) async {
      await pumpSheet(tester, _FakeCategoryRepository());

      expect(find.text('Продукты'), findsOneWidget);
      expect(find.text('Хобби'), findsOneWidget);
    },
  );

  testWidgets(
    '"+ create" opens the inline form without closing the parent sheet',
    (WidgetTester tester) async {
      await pumpSheet(tester, _FakeCategoryRepository());

      expect(find.text('+ Своя категория'), findsOneWidget);
      await tester.tap(find.text('+ Своя категория'));
      await tester.pumpAndSettle();

      // The inline form is visible...
      expect(find.widgetWithText(TextField, 'Название'), findsOneWidget);
      expect(find.text('Создать'), findsOneWidget);
      // ...and the parent sheet (with the existing grid) never closed.
      expect(find.text('Выберите категорию'), findsOneWidget);
      expect(find.text('Продукты'), findsOneWidget);
    },
  );

  testWidgets(
    'creating a category adds it to the grid and returns to the picker view',
    (WidgetTester tester) async {
      await pumpSheet(tester, _FakeCategoryRepository());

      await tester.tap(find.text('+ Своя категория'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Название'),
        'Спорт',
      );
      await tester.tap(find.text('Создать'));
      await tester.pumpAndSettle();

      expect(find.text('Спорт'), findsOneWidget);
      // Back to the picker view, form is gone.
      expect(find.widgetWithText(TextField, 'Название'), findsNothing);
    },
  );

  testWidgets(
    'tapping a category closes the sheet and returns it',
    (WidgetTester tester) async {
      Category? picked;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
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
                        onPressed: () async {
                          picked = await CategoryPickerSheet.show(context);
                        },
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

      await tester.tap(find.text('Продукты'));
      await tester.pumpAndSettle();

      expect(picked?.id, 'system-1');
      expect(find.text('Выберите категорию'), findsNothing);
    },
  );
}
