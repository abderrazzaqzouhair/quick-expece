import 'package:database/database.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quik_expense_mobile/features/home/logic/home_extras.dart';

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

  test('quick add: most used first, ties by most recent', () async {
    final all = await seed([
      ('Food & Drinks', 'Coffee', 100, DateTime(2026, 10, 1)),
      ('Food & Drinks', 'Coffee', 100, DateTime(2026, 10, 2)),
      ('Transport', 'Taxi', 100, DateTime(2026, 10, 3)),
      ('Transport', 'Bus', 100, DateTime(2026, 10, 4)), // newer tie
    ]);
    final items = quickAddSuggestions(all);
    expect(items.map((i) => (i.subcategory.name, i.count)), [
      ('Coffee', 2),
      ('Bus', 1),
      ('Taxi', 1),
    ]);
    expect(quickAddSuggestions(all, max: 1), hasLength(1));
    expect(quickAddRange(DateTime(2026, 10, 6)).from, DateTime(2026, 8, 7));
  });

  test('week totals per day from Monday', () async {
    final all = await seed([
      ('Food & Drinks', 'Coffee', 300, DateTime(2026, 10, 5, 9)), // Mon
      ('Transport', 'Taxi', 1000, DateTime(2026, 10, 7, 20)), // Wed
      ('Transport', 'Bus', 200, DateTime(2026, 10, 7, 8)),
      ('Transport', 'Bus', 999, DateTime(2026, 10, 12)), // next Mon
    ]);
    expect(weekTotals(all, DateTime(2026, 10, 5)), [300, 0, 1200, 0, 0, 0, 0]);
  });

  test('insights: projection, category change, biggest, no-spend', () async {
    final all = await seed([
      ('Food & Drinks', 'Groceries', 20000, DateTime(2026, 10, 2)),
      ('Food & Drinks', 'Coffee', 1000, DateTime(2026, 10, 4)),
      ('Food & Drinks', 'Restaurants', 10000, DateTime(2026, 9, 10)),
    ]);
    final now = DateTime(2026, 10, 6, 12);
    final insights = buildInsights(all, now, now: now, max: 4);

    expect(insights.map((i) => i.kind), [
      InsightKind.projection,
      InsightKind.categoryUp,
      InsightKind.biggest,
      InsightKind.noSpendDays,
    ]);
    // 210.00 over 6 days × 31 days = 1,085.00
    expect(insights[0].highlight, '~1,085.00 MAD');
    expect(insights[1].text, 'Food & Drinks is up 110% vs last month');
    expect(insights[2].text, startsWith('Biggest expense: Groceries'));
    expect(insights[3].highlight, '4 no-spend days'); // 6 days, 2 with spend
    expect(insights[0].text, contains(insights[0].highlight));

    expect(buildInsights(all, now, now: now), hasLength(3)); // default max
    expect(buildInsights(all, DateTime(2026, 11, 1), now: now), isEmpty);

    // Past month: no projection, "that month" wording.
    final sept = buildInsights(all, DateTime(2026, 9, 1), now: now, max: 4);
    expect(sept.map((i) => i.kind), isNot(contains(InsightKind.projection)));
    expect(sept.last.text, endsWith('that month'));
  });
}
