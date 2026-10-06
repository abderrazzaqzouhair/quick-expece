import 'package:database/database.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quik_expense_mobile/features/statistics/logic/period_details.dart';
import 'package:quik_expense_mobile/features/statistics/logic/period_stats.dart';

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

  final now = DateTime(2026, 10, 10, 18); // Saturday

  test('month details: top subs, largest, habits', () async {
    final all = await seed([
      ('Food & Drinks', 'Coffee', 300, DateTime(2026, 10, 1, 8)), // Thu
      ('Food & Drinks', 'Coffee', 300, DateTime(2026, 10, 2, 8)), // Fri
      ('Food & Drinks', 'Coffee', 300, DateTime(2026, 10, 3, 8)), // Sat
      ('Transport', 'Fuel', 40000, DateTime(2026, 10, 3, 12)), // Sat
      ('Food & Drinks', 'Groceries', 9000, DateTime(2026, 10, 5)), // Mon
      ('Transport', 'Taxi', 9999, DateTime(2026, 9, 30)), // last month
    ]);
    final d = buildPeriodDetails(
      StatsPeriod.month,
      windowFor(StatsPeriod.month, now),
      all,
      now,
    );

    expect(d.topSubcategories.map((s) => (s.subcategory.name, s.count)), [
      ('Fuel', 1),
      ('Groceries', 1),
      ('Coffee', 3),
    ]);
    expect(d.largest.first.subcategory.name, 'Fuel');
    expect(d.count, 5);
    expect(d.averageExpenseCents, 49900 ~/ 5);
    expect(d.mostFrequent!.subcategory.name, 'Coffee');

    // Oct 1–10 elapsed; spending on the 1st, 2nd, 3rd and 5th.
    expect(d.elapsedDays, 10);
    expect(d.noSpendDays, 6);

    // Saturdays elapsed: Oct 3 and Oct 10 → (300 + 40000) / 2.
    expect(d.weekdayAverages[5], 40300 ~/ 2);
    expect(d.topWeekday, 5); // Saturday
  });

  test('all: days counted from the first expense', () async {
    final all = await seed([('Transport', 'Bus', 100, DateTime(2026, 10, 8))]);
    final d = buildPeriodDetails(
      StatsPeriod.all,
      windowFor(StatsPeriod.all, now),
      all,
      now,
    );
    expect(d.elapsedDays, 3); // Oct 8, 9, 10
    expect(d.noSpendDays, 2);
    expect(d.topWeekday, isNull); // a single weekday is no pattern
  });

  test('empty period', () async {
    final d = buildPeriodDetails(
      StatsPeriod.week,
      windowFor(StatsPeriod.week, now),
      const [],
      now,
    );
    expect(d.topSubcategories, isEmpty);
    expect(d.mostFrequent, isNull);
    expect(d.averageExpenseCents, 0);
    expect(d.elapsedDays, 6); // Mon–Sat
  });
}
