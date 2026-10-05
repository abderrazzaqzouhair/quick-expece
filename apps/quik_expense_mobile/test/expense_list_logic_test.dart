import 'package:database/database.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quik_expense_mobile/features/expense_list/logic/expense_list_view.dart';
import 'package:quik_expense_mobile/features/statistics/logic/period_stats.dart';

void main() {
  late AppDatabase db;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  String sub(String c, String s) => CatalogueSeeder.subcategoryId(c, s);

  Future<List<ExpenseDetails>> seed(
    List<(String, String, int, DateTime, String?)> rows,
  ) async {
    for (final (c, s, cents, date, note) in rows) {
      await db.expensesDao.add(
        subcategoryId: sub(c, s),
        amountCents: cents,
        date: date,
        note: note,
      );
    }
    return db.expensesDao.watchDetails().first;
  }

  group('expense list view', () {
    test('category and search filters narrow the list', () async {
      final all = await seed([
        ('Food & Drinks', 'Coffee', 500, DateTime(2026, 9, 3), 'Latte'),
        ('Transport', 'Taxi', 3000, DateTime(2026, 9, 2), null),
        ('Transport', 'Bus', 1000, DateTime(2026, 9, 1), 'Airport run'),
      ]);
      final transportId = all
          .firstWhere((e) => e.category.name == 'Transport')
          .category
          .id;

      final byCategory = buildExpenseListView(
        all,
        ExpenseListFilters(period: StatsPeriod.month, categoryId: transportId),
        visibleCount: 30,
      );
      expect(byCategory.filteredCount, 2);
      expect(byCategory.periodCount, 3); // unfiltered count unaffected

      final bySearch = buildExpenseListView(
        all,
        const ExpenseListFilters(period: StatsPeriod.month, query: 'airport'),
        visibleCount: 30,
      );
      expect(bySearch.filteredCount, 1);
      expect(bySearch.groups.single.items.single.expense.note, 'Airport run');
    });

    test(
      'sort reorders by date or amount; amount sort skips day-grouping',
      () async {
        final all = await seed([
          ('Food & Drinks', 'Coffee', 500, DateTime(2026, 9, 1), null),
          ('Transport', 'Taxi', 3000, DateTime(2026, 9, 3), null),
          ('Transport', 'Bus', 1000, DateTime(2026, 9, 2), null),
        ]);

        final oldest = buildExpenseListView(
          all,
          const ExpenseListFilters(
            period: StatsPeriod.month,
            sort: ExpenseSort.dateAsc,
          ),
          visibleCount: 30,
        );
        expect(oldest.groups.first.items.single.expense.amountCents, 500);
        expect(oldest.flatItems, isEmpty);

        final highest = buildExpenseListView(
          all,
          const ExpenseListFilters(
            period: StatsPeriod.month,
            sort: ExpenseSort.amountDesc,
          ),
          visibleCount: 30,
        );
        expect(highest.groups, isEmpty);
        expect(highest.flatItems.map((e) => e.expense.amountCents), [
          3000, 1000, 500, //
        ]);
      },
    );

    test('isEmptyPeriod vs isEmptyFiltered', () async {
      final all = await seed([
        ('Food & Drinks', 'Coffee', 500, DateTime(2026, 9, 1), null),
      ]);

      final noData = buildExpenseListView(
        const [],
        const ExpenseListFilters(period: StatsPeriod.month),
        visibleCount: 30,
      );
      expect(noData.isEmptyPeriod, isTrue);
      expect(noData.isEmptyFiltered, isFalse);

      final noMatches = buildExpenseListView(
        all,
        const ExpenseListFilters(period: StatsPeriod.month, query: 'nope'),
        visibleCount: 30,
      );
      expect(noMatches.isEmptyPeriod, isFalse);
      expect(noMatches.isEmptyFiltered, isTrue);
    });

    test('pagination slices the visible page and reports hasMore', () async {
      final rows = [
        for (var i = 0; i < 5; i++)
          ('Food & Drinks', 'Coffee', 100, DateTime(2026, 9, 1 + i), null),
      ];
      final all = await seed(rows);

      final page = buildExpenseListView(
        all,
        const ExpenseListFilters(period: StatsPeriod.month),
        visibleCount: 2,
      );
      expect(page.visibleCount, 2);
      expect(page.filteredCount, 5);
      expect(page.hasMore, isTrue);

      final fullPage = buildExpenseListView(
        all,
        const ExpenseListFilters(period: StatsPeriod.month),
        visibleCount: 30,
      );
      expect(fullPage.hasMore, isFalse);
    });
  });
}
