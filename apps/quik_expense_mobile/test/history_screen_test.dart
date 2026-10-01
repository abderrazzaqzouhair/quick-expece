import 'package:database/database.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quik_expense_mobile/config/providers/database_providers.dart';
import 'package:quik_expense_mobile/features/history/history_screen.dart';
import 'package:quik_expense_mobile/features/history/widgets/history_skeleton.dart';

void main() {
  late AppDatabase db;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  String sub(String c, String s) => CatalogueSeeder.subcategoryId(c, s);

  Future<void> seed(WidgetTester tester) => tester.runAsync(() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 9);
    await db.expensesDao.add(
      subcategoryId: sub('Food & Drinks', 'Coffee'),
      amountCents: 450,
      date: today,
      note: 'Latte with Sara',
    );
    await db.expensesDao.add(
      subcategoryId: sub('Transport', 'Taxi'),
      amountCents: 3000,
      date: today.add(const Duration(hours: 1)),
    );
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1179, 2556)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: HistoryScreen()),
      ),
    );
    await settleDb(tester);
  }

  testWidgets('shows month total and today\'s expenses', (tester) async {
    await seed(tester);
    await pump(tester);

    expect(find.textContaining('2 expenses'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('34.50 MAD'), findsOneWidget); // day total
    expect(find.text('Taxi'), findsOneWidget);
    expect(find.text('Coffee'), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('category chip and search filter the list', (tester) async {
    await seed(tester);
    await pump(tester);

    await tester.tap(find.text('Transport'));
    await tester.pumpAndSettle();
    expect(find.text('Coffee'), findsNothing);
    expect(find.text('1 result  ·  30.00 MAD'), findsOneWidget);

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'nothing-matches');
    await tester.pumpAndSettle();
    expect(find.text('No matches'), findsOneWidget);

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(find.text('Coffee'), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('swipe to delete, then undo', (tester) async {
    await seed(tester);
    await pump(tester);

    await tester.drag(find.text('Taxi'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await settleDb(tester);
    expect(find.text('Taxi'), findsNothing);
    expect(find.text('Taxi · 30.00 MAD deleted'), findsOneWidget);
    expect(find.textContaining('1 expense'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await settleDb(tester);
    expect(find.text('Taxi'), findsOneWidget);

    final rows = (await tester.runAsync(
      () => db.expensesDao.watchDetails().first,
    ))!;
    expect(rows, hasLength(2));

    await disposeTree(tester);
  });

  testWidgets('skeleton while loading, then content', (tester) async {
    await seed(tester);
    tester.view
      ..physicalSize = const Size(1179, 2556)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: HistoryScreen()),
      ),
    );
    // The database hasn't answered yet (it needs real async time).
    expect(find.byType(HistorySkeleton), findsOneWidget);
    expect(find.text('Taxi'), findsNothing);

    await settleDb(tester);
    expect(find.byType(HistorySkeleton), findsNothing);
    expect(find.text('Taxi'), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('empty month shows a call to action', (tester) async {
    await pump(tester);
    expect(find.text('Add expense'), findsOneWidget);
    expect(find.textContaining('No expenses in'), findsOneWidget);
    await disposeTree(tester);
  });
}

Future<void> settleDb(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
}

Future<void> disposeTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 6)); // toast + drift timers
}
