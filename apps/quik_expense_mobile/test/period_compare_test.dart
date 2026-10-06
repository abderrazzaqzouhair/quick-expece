import 'package:database/database.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quik_expense_mobile/features/statistics/logic/period_compare.dart';
import 'package:quik_expense_mobile/features/statistics/logic/period_stats.dart';
import 'package:quik_expense_mobile/shared/csv_export.dart';

void main() {
  late AppDatabase db;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  String sub(String c, String s) => CatalogueSeeder.subcategoryId(c, s);

  Future<List<ExpenseDetails>> seed(
    List<(String, String, int, DateTime)> rows,
  ) async {
    for (final (c, s, cents, date) in rows) {
      await db.expensesDao.add(
        subcategoryId: sub(c, s),
        amountCents: cents,
        date: date,
      );
    }
    return db.expensesDao.watchDetails().first;
  }

  final now = DateTime(2026, 10, 10, 12);

  test('compares totals and every category in either period', () async {
    final all = await seed([
      ('Food & Drinks', 'Coffee', 1000, DateTime(2026, 10, 2)),
      ('Transport', 'Fuel', 6000, DateTime(2026, 10, 3)),
      ('Food & Drinks', 'Groceries', 4000, DateTime(2026, 9, 5)),
      ('Travel', 'Hotels', 9000, DateTime(2026, 9, 20)), // only last month
    ]);
    final window = windowFor(StatsPeriod.month, now);
    final c = comparePeriods(window, all);

    expect(c.currentTotalCents, 7000);
    expect(c.previousTotalCents, 13000);
    expect(c.differenceCents, -6000);
    expect(c.deltaPercent, -46);
    expect(
      c.categories.map(
        (x) => (x.category.name, x.currentCents, x.previousCents),
      ),
      [
        ('Travel', 0, 9000), // biggest of the two amounts first
        ('Transport', 6000, 0),
        ('Food & Drinks', 1000, 4000),
      ],
    );
    expect(c.categories[1].deltaPercent, isNull); // new this month
    expect(c.categories.last.deltaPercent, -75);

    expect(rangeName(StatsPeriod.month, window.current, now), 'October');
    expect(rangeName(StatsPeriod.month, window.previous, now), 'September');
  });

  test('shifted ranges and their names', () {
    final day = windowFor(StatsPeriod.today, now);
    final fiveAgo = shiftedRange(StatsPeriod.today, day, 5);
    expect(fiveAgo.from, DateTime(2026, 10, 5));
    expect(fiveAgo.to, DateTime(2026, 10, 6));
    expect(rangeName(StatsPeriod.today, fiveAgo, now), 'Mon, Oct 5');
    expect(
      rangeName(
        StatsPeriod.today,
        shiftedRange(StatsPeriod.today, day, 1),
        now,
      ),
      'Yesterday',
    );

    final week = windowFor(StatsPeriod.week, now); // Oct 5 – Oct 11
    expect(rangeName(StatsPeriod.week, week.current, now), 'This week');
    expect(
      rangeName(StatsPeriod.week, shiftedRange(StatsPeriod.week, week, 1), now),
      'Last week',
    );
    final twoAgo = shiftedRange(StatsPeriod.week, week, 2);
    expect(twoAgo.from, DateTime(2026, 9, 21));
    expect(rangeName(StatsPeriod.week, twoAgo, now), 'Sep 21 – Sep 27');

    final month = windowFor(StatsPeriod.month, now);
    final feb = shiftedRange(StatsPeriod.month, month, 8);
    expect(feb.from, DateTime(2026, 2));
    expect(feb.to, DateTime(2026, 3));
    expect(
      rangeName(
        StatsPeriod.month,
        shiftedRange(StatsPeriod.month, month, 13),
        now,
      ),
      'September 2025',
    );

    final year = windowFor(StatsPeriod.year, now);
    expect(
      rangeName(StatsPeriod.year, shiftedRange(StatsPeriod.year, year, 1), now),
      'Nov 2024 – Oct 2025',
    );
  });

  test('period CSV only contains the given expenses, oldest first', () async {
    final all = await seed([
      ('Transport', 'Fuel', 6000, DateTime(2026, 10, 3, 9)),
      ('Food & Drinks', 'Coffee', 1000, DateTime(2026, 10, 2, 8)),
    ]);
    final csv = expensesCsv(all).split('\n');
    expect(csv[1], startsWith('2026-10-02,08:00,Food & Drinks,Coffee,10.00'));
    expect(csv[2], startsWith('2026-10-03,09:00,Transport,Fuel,60.00'));
  });
}
