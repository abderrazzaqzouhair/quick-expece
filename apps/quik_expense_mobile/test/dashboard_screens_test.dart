import 'package:database/database.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:quik_expense_mobile/config/providers/database_providers.dart';
import 'package:quik_expense_mobile/config/providers/preferences_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    Map<String, Object> prefsValues = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefsValues);
    final prefs = await SharedPreferences.getInstance();
    tester.view
      ..physicalSize = const Size(1179, 2556)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(home: screen),
      ),
    );
  }

  group('Home', () {
    testWidgets('skeleton, then totals with context and recent expenses', (
      tester,
    ) async {
      await seed(tester);
      await pump(
        tester,
        const HomeScreen(),
        prefsValues: {'profile.name': 'Sara Alaoui'},
      );
      expect(find.byType(HomeSkeleton), findsOneWidget);

      await settleDb(tester);
      expect(find.byType(HomeSkeleton), findsNothing);
      expect(find.textContaining(', Sara'), findsOneWidget); // greeting
      expect(find.text('34.50 MAD'), findsWidgets); // today + this month
      expect(find.text('2 expenses'), findsOneWidget); // today's detail
      expect(find.text('↑ 245% vs last month'), findsOneWidget); // 34.50 vs 10
      expect(find.text('Taxi'), findsWidgets); // recent row + quick add
      expect(find.text('30.00 MAD'), findsWidgets); // no minus sign

      await disposeTree(tester);
    });

    testWidgets('quick add, this week and insights sections', (tester) async {
      await seed(tester);
      await pump(tester, const HomeScreen());
      await settleDb(tester);

      expect(find.text('Quick add'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('^Add Coffee expense')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('^Add Taxi expense')),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.text('This Week'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('This Week'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Insights'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Biggest expense: Taxi'), findsOneWidget);

      await disposeTree(tester);
    });

    testWidgets('calendar: full month by default, collapses to a week', (
      tester,
    ) async {
      await seed(tester);
      await pump(tester, const HomeScreen());
      await settleDb(tester);

      final dayCells = find.bySemanticsLabel(RegExp(r'^\w+ \d{1,2}, \d{4}'));
      expect(dayCells.evaluate().length, greaterThanOrEqualTo(28));

      await tester.tap(find.bySemanticsLabel(RegExp('Show week')));
      await tester.pumpAndSettle();
      expect(dayCells, findsNWidgets(7));

      await tester.tap(find.bySemanticsLabel(RegExp('Show month')));
      await tester.pumpAndSettle();
      expect(dayCells.evaluate().length, greaterThanOrEqualTo(28));

      await disposeTree(tester);
    });

    testWidgets('first run shows the welcome card', (tester) async {
      await pump(tester, const HomeScreen());
      await settleDb(tester);
      expect(find.text('Start tracking your spending'), findsOneWidget);
      expect(find.text('Add your first expense'), findsOneWidget);
      expect(find.text('Top Categories'), findsNothing);
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
      expect(find.text('Spending Trend'), findsOneWidget);
      expect(
        find.textContaining('245% vs last month', findRichText: true),
        findsOneWidget,
      ); // 34.50 vs 10.00
      expect(find.text('By Category'), findsOneWidget);
      expect(find.text('New'), findsOneWidget); // Food: nothing last month

      await disposeTree(tester);
    });

    testWidgets('top subcategories, habits and largest expenses', (
      tester,
    ) async {
      await seed(tester);
      await pump(tester, const StatisticsScreen());
      await settleDb(tester);
      final scrollable = find.byType(Scrollable).first;

      await tester.scrollUntilVisible(
        find.text('Top Subcategories'),
        300,
        scrollable: scrollable,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'^1\. Taxi, 30\.00 MAD')),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.text('Spending Habits'),
        300,
        scrollable: scrollable,
      );
      expect(find.text('Avg per expense'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Largest Expenses'),
        300,
        scrollable: scrollable,
      );
      // Tapping a largest expense opens its detail sheet.
      await tester.tap(find.bySemanticsLabel(RegExp(r'^Taxi, 30\.00 MAD, ')));
      await tester.pumpAndSettle();
      expect(find.text('Delete Expense'), findsOneWidget);

      await disposeTree(tester);
    });

    testWidgets('export copies the period CSV; compare opens the sheet', (
      tester,
    ) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await seed(tester);
      await pump(tester, const StatisticsScreen());
      await settleDb(tester);
      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Export'),
        400,
        scrollable: scrollable,
      );

      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();
      // This month only: the two expenses from today, not last month's.
      expect(copied, isNotNull);
      expect(copied!.trim().split('\n'), hasLength(3)); // header + 2
      expect(copied, isNot(contains('Bus')));
      expect(find.textContaining('2 expenses copied'), findsOneWidget);

      await tester.tap(find.text('Compare'));
      await tester.pumpAndSettle();
      expect(find.text('By category'), findsOneWidget);
      expect(find.textContaining('more (245%) than'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // "All" has nothing to compare with.
      await tester.scrollUntilVisible(
        find.text('All'),
        -400,
        scrollable: scrollable,
      );
      await tester.tap(find.text('All'));
      await settleDb(tester);
      await tester.scrollUntilVisible(
        find.text('Export'),
        400,
        scrollable: scrollable,
      );
      expect(find.text('Compare'), findsNothing);

      await disposeTree(tester);
    });

    testWidgets('compare: pick another week, or any day for Today', (
      tester,
    ) async {
      await seed(tester);
      await pump(tester, const StatisticsScreen());
      await settleDb(tester);
      final scrollable = find.byType(Scrollable).first;

      await tester.tap(find.text('Week'));
      await settleDb(tester);
      await tester.scrollUntilVisible(
        find.text('Compare'),
        400,
        scrollable: scrollable,
      );
      await tester.tap(find.text('Compare'));
      await settleDb(tester);
      expect(
        find.bySemanticsLabel(RegExp('^Compare with Last week')),
        findsOneWidget,
      );

      // Pick the week before last from the list.
      await tester.tap(find.bySemanticsLabel(RegExp('^Compare with')));
      await tester.pumpAndSettle();
      expect(find.text('Compare with week'), findsOneWidget);
      final twoWeeksAgo = DateTime.now().subtract(
        Duration(days: DateTime.now().weekday - 1 + 14),
      );
      final label = DateFormat.MMMd('en_US').format(twoWeeksAgo);
      await tester.tap(find.textContaining('$label – '));
      await settleDb(tester);
      expect(
        find.bySemanticsLabel(RegExp('^Compare with $label – ')),
        findsOneWidget,
      );
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Today: the picker is a date wheel.
      await tester.scrollUntilVisible(
        find.text('Today'),
        -400,
        scrollable: scrollable,
      );
      await tester.tap(find.text('Today'));
      await settleDb(tester);
      await tester.scrollUntilVisible(
        find.text('Compare'),
        400,
        scrollable: scrollable,
      );
      await tester.tap(find.text('Compare'));
      await settleDb(tester);
      expect(
        find.bySemanticsLabel(RegExp('^Compare with Yesterday')),
        findsOneWidget,
      );
      await tester.tap(find.bySemanticsLabel(RegExp('^Compare with')));
      await tester.pumpAndSettle();
      expect(find.text('Date'), findsOneWidget); // the date sheet

      await disposeTree(tester);
    });

    testWidgets('today hides spending habits', (tester) async {
      await seed(tester);
      await pump(tester, const StatisticsScreen());
      await settleDb(tester);
      await tester.tap(find.text('Today'));
      await settleDb(tester);
      await tester.scrollUntilVisible(
        find.text('Largest Expenses'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Spending Habits'), findsNothing);
      await disposeTree(tester);
    });

    testWidgets('trend card: tap a bar to move the bubble', (tester) async {
      await seed(tester);
      await pump(tester, const StatisticsScreen());
      await settleDb(tester);
      await tester.tap(find.text('Week'));
      await settleDb(tester);

      // Today's bar is selected by default; tapping another day selects it.
      final today = DateTime.now();
      final other = today.weekday == DateTime.monday
          ? today.add(const Duration(days: 1))
          : today.subtract(const Duration(days: 1));
      Finder bar(DateTime d) => find.bySemanticsLabel(
        RegExp('^${DateFormat.E('en_US').format(d)}: '),
      );
      void expectSelected(DateTime d, bool selected) => expect(
        tester.getSemantics(bar(d)),
        containsSemantics(isSelected: selected),
      );

      expectSelected(today, true);
      expectSelected(other, false);

      await tester.tap(bar(other));
      await tester.pumpAndSettle();
      expectSelected(other, true);
      expectSelected(today, false);

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
