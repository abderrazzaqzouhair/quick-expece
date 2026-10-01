import 'package:database/database.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quik_expense_mobile/config/providers/database_providers.dart';
import 'package:quik_expense_mobile/features/home/home_screen.dart';
import 'package:quik_expense_mobile/features/home/widgets/home_skeleton.dart';
import 'package:quik_expense_mobile/features/statistics/statistics_screen.dart';
import 'package:quik_expense_mobile/features/statistics/widgets/statistics_skeleton.dart';

void main() {
  late AppDatabase db;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  String sub(String c, String s) => CatalogueSeeder.subcategoryId(c, s);

  /// Today: Coffee 4.50 + Taxi 30.00; last month: Bus 10.00 (Transport).
  Future<void> seed(WidgetTester tester) => tester.runAsync(() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 9);
    await db.expensesDao.add(
      subcategoryId: sub('Food & Drinks', 'Coffee'),
      amountCents: 450,
      date: today,
    );
    await db.expensesDao.add(
      subcategoryId: sub('Transport', 'Taxi'),
      amountCents: 3000,
      date: today.add(const Duration(hours: 1)),
    );
    await db.expensesDao.add(
      subcategoryId: sub('Transport', 'Bus'),
      amountCents: 1000,
      date: DateTime(now.year, now.month - 1, 10),
    );
  });

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view
      ..physicalSize = const Size(1179, 2556)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: screen),
      ),
    );
  }

  group('Home', () {
    testWidgets('skeleton, then real totals and recent expenses', (
      tester,
    ) async {
      await seed(tester);
      await pump(tester, const HomeScreen());
      expect(find.byType(HomeSkeleton), findsOneWidget);

      await settleDb(tester);
      expect(find.byType(HomeSkeleton), findsNothing);
      expect(find.text('34.50 MAD'), findsWidgets); // today + this month
      expect(find.text('Transport'), findsWidgets);
      expect(find.text('-30.00 MAD'), findsOneWidget); // recent row

      await disposeTree(tester);
    });

    testWidgets('empty database shows friendly empty states', (tester) async {
      await pump(tester, const HomeScreen());
      await settleDb(tester);
      expect(find.text('No expenses'), findsNWidgets(2));
      expect(
        find.textContaining('top categories will show up'),
        findsOneWidget,
      );
      expect(find.text('No expenses yet.'), findsOneWidget);
      await disposeTree(tester);
    });
  });

  group('Statistics', () {
    testWidgets('month: totals, trend vs last month, breakdown', (
      tester,
    ) async {
      await seed(tester);
      await pump(tester, const StatisticsScreen());
      expect(find.byType(StatisticsSkeleton), findsOneWidget);

      await settleDb(tester);
      expect(find.byType(StatisticsSkeleton), findsNothing);
      expect(find.text('34.50 MAD'), findsWidgets); // total spent
      expect(find.text('245% vs last period'), findsOneWidget); // 3450 vs 1000
      expect(find.text('By Category'), findsOneWidget);
      expect(find.text('New'), findsOneWidget); // Food: nothing last month

      await disposeTree(tester);
    });

    testWidgets('switching period keeps content and recomputes', (
      tester,
    ) async {
      await seed(tester);
      await pump(tester, const StatisticsScreen());
      await settleDb(tester);

      await tester.tap(find.text('6M'));
      await tester.pump();
      // Previous stats stay on screen (no skeleton flash) while loading.
      expect(find.byType(StatisticsSkeleton), findsNothing);
      await settleDb(tester);
      expect(find.text('Monthly Avg'), findsOneWidget);
      expect(find.text('44.50 MAD'), findsWidgets); // both months in range

      await disposeTree(tester);
    });

    testWidgets('empty period explains and offers to add', (tester) async {
      await pump(tester, const StatisticsScreen());
      await settleDb(tester);
      expect(find.text('No expenses this month'), findsOneWidget);
      expect(find.text('Add expense'), findsOneWidget);
      await disposeTree(tester);
    });
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
  await tester.pump(const Duration(seconds: 1));
}
