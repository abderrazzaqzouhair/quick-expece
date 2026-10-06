import 'package:database/database.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quik_expense_mobile/config/providers/database_providers.dart';
import 'package:quik_expense_mobile/features/add_expense/add_expense_screen.dart';
import 'package:ui_kit/ui_kit.dart' show AppSkeleton;

void main() {
  late AppDatabase db;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// Home stub → pushes the screen, like the bottom-nav "create" button.
  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view
      ..physicalSize =
          const Size(1179, 2556) // iPhone 15
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.push('/add'),
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(path: '/add', builder: (_, _) => const AddExpenseScreen()),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.tap(find.text('open'));
    await settleDb(tester);
  }

  testWidgets('keypad → category sheet → save', (tester) async {
    await pumpScreen(tester);
    expect(find.text('New Expense'), findsOneWidget);
    expect(find.text('Enter an amount'), findsOneWidget);

    await typeAmount(tester, '1250.5');
    expect(find.text('1,250.5'), findsOneWidget);
    expect(find.text('Choose a category'), findsOneWidget);

    // The guiding button opens the category sheet.
    await tester.tap(find.text('Choose a category'));
    await settleDb(tester);
    await tester.tap(find.text('Transport'));
    await settleDb(tester);
    await tester.tap(find.text('Bus'));
    await tester.pumpAndSettle();

    expect(find.text('Bus'), findsOneWidget); // shown in the category field
    expect(find.text('Save  ·  1,250.50 MAD'), findsOneWidget);

    await tester.tap(find.text('Save  ·  1,250.50 MAD'));
    await settleDb(tester);

    expect(find.text('open'), findsOneWidget); // popped
    expect(find.text('1,250.50 MAD · Bus saved'), findsOneWidget);

    final saved = (await tester.runAsync(
      () => db.expensesDao.watchDetails().first,
    ))!;
    expect(saved, hasLength(1));
    expect(saved.single.expense.amountCents, 125050);
    expect(saved.single.subcategory.name, 'Bus');
    expect(saved.single.category.name, 'Transport');

    await disposeTree(tester);
  });

  testWidgets('note and date are saved', (tester) async {
    await pumpScreen(tester);
    await typeAmount(tester, '9');

    await tester.tap(find.text('Add note'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  Coffee with Ali ');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Coffee with Ali'), findsOneWidget);

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yesterday'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Yesterday'), findsOneWidget);

    await tester.tap(find.text('Choose a category'));
    await settleDb(tester);
    await tester.tap(find.text('Food & Drinks'));
    await settleDb(tester);
    await tester.tap(find.text('Coffee'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Save'));
    await settleDb(tester);

    final saved = (await tester.runAsync(
      () => db.expensesDao.watchDetails().first,
    ))!;
    final expense = saved.single.expense;
    expect(expense.note, 'Coffee with Ali');
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    expect(
      DateTime(expense.date.year, expense.date.month, expense.date.day),
      yesterday,
    );

    await disposeTree(tester);
  });

  testWidgets('category sheet shows a skeleton until loaded', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Choose category'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // sheet slides up
    expect(find.byType(AppSkeleton), findsWidgets);

    await settleDb(tester);
    expect(find.byType(AppSkeleton), findsNothing);
    expect(find.text('Travel'), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('opens with a pre-picked category (Quick Add)', (tester) async {
    final transport = (await tester.runAsync(
      () => db.categoriesDao.findById(CatalogueSeeder.categoryId('Transport')),
    ))!;
    final taxi = (await tester.runAsync(
      () => db.subcategoriesDao.findById(
        CatalogueSeeder.subcategoryId('Transport', 'Taxi'),
      ),
    ))!;
    tester.view
      ..physicalSize = const Size(1179, 2556)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: AddExpenseScreen(
            initialChoice: (category: transport, subcategory: taxi),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Taxi'), findsOneWidget);
    expect(find.text('Choose category'), findsNothing);
    expect(find.text('Enter an amount'), findsOneWidget); // only step left

    await typeAmount(tester, '25');
    expect(find.text('Save  ·  25.00 MAD'), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('save without an amount stays on the screen', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Enter an amount'));
    await tester.pumpAndSettle();
    expect(find.text('New Expense'), findsOneWidget);

    // Backspace on empty and a second decimal point are ignored.
    await typeAmount(tester, '..');
    expect(find.text('0.'), findsOneWidget);

    await disposeTree(tester);
  });
}

/// Taps keypad keys for each character of [amount].
Future<void> typeAmount(WidgetTester tester, String amount) async {
  const names = {'.': 'decimal'};
  for (final char in amount.split('')) {
    final name = names[char] ?? 'd$char';
    await tester.tap(find.byKey(ValueKey('amount-key-$name')));
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

/// Drift runs its queries on real async time, which the widget tester's
/// fake clock never advances — give it a moment, then settle the UI.
Future<void> settleDb(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
}

/// Unmounts the app so drift's stream subscriptions close, then lets its
/// cancellation timer fire (the tester fails on pending timers).
Future<void> disposeTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}
