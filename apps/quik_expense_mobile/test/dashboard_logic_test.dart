import 'package:database/database.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quik_expense_mobile/features/home/logic/home_view.dart';
import 'package:quik_expense_mobile/features/statistics/logic/period_stats.dart';
import 'package:quik_expense_mobile/shared/spending.dart';

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

  group('spending', () {
    test('percentChange', () {
      expect(percentChange(120, 100), 20);
      expect(percentChange(80, 100), -20);
      expect(percentChange(50, 0), isNull);
    });

    test('categoryTotals ranks and attaches previous', () async {
      final all = await seed([
        ('Transport', 'Taxi', 3000, DateTime(2026, 9, 2)),
        ('Food & Drinks', 'Coffee', 500, DateTime(2026, 9, 3)),
        ('Transport', 'Bus', 1000, DateTime(2026, 8, 3)),
      ]);
      final sept = inRange(all, (
        from: DateTime(2026, 9),
        to: DateTime(2026, 10),
      ));
      final aug = inRange(all, (
        from: DateTime(2026, 8),
        to: DateTime(2026, 9),
      ));
      final totals = categoryTotals(sept, previous: aug);
      expect(
        totals.map((t) => (t.category.name, t.totalCents, t.deltaPercent)),
        [
          ('Transport', 3000, 200),
          ('Food & Drinks', 500, null), // new this month
        ],
      );
    });
  });

  group('home', () {
    test('calendar grid is whole Monday-first weeks', () {
      final grid = calendarGrid(DateTime(2026, 10)); // 1 Oct 2026 = Thursday
      expect(grid.length % 7, 0);
      expect(grid.first, DateTime(2026, 9, 28)); // Monday
      expect(grid.first.weekday, DateTime.monday);
      expect(grid.last.weekday, DateTime.sunday);
      expect(grid, contains(DateTime(2026, 10, 31)));
    });

    test('day / month totals and category trend', () async {
      final all = await seed([
        ('Food & Drinks', 'Coffee', 450, DateTime(2026, 9, 15, 9)),
        ('Transport', 'Taxi', 3000, DateTime(2026, 9, 15, 19)),
        ('Transport', 'Bus', 600, DateTime(2026, 9, 2)),
        ('Transport', 'Bus', 1800, DateTime(2026, 8, 10)),
      ]);

      final view = buildHomeView(all, DateTime(2026, 9, 15));
      expect(view.dayTotalCents, 3450);
      expect(view.monthTotalCents, 4050);
      expect(view.categories.first.category.name, 'Transport');
      expect(view.categories.first.deltaPercent, 100); // 3600 vs 1800

      final quietDay = buildHomeView(all, DateTime(2026, 9, 16));
      expect(quietDay.dayTotalCents, isNull);

      final emptyMonth = buildHomeView(all, DateTime(2026, 11, 1));
      expect(emptyMonth.monthTotalCents, isNull);
      expect(emptyMonth.categories, isEmpty);

      expect(daysWithSpend(all), contains(DateTime(2026, 9, 15)));

      expect(view.dayCount, 2);
      expect(view.monthCount, 3);
      expect(view.previousMonthCents, 1800);
      expect(view.monthDeltaPercent, 125); // 4050 vs 1800
      expect(emptyMonth.monthDeltaPercent, isNull);
    });

    test('weekOf is Monday-first and DST-safe', () {
      final week = weekOf(DateTime(2026, 10, 1)); // Thursday
      expect(week.first, DateTime(2026, 9, 28));
      expect(week.last, DateTime(2026, 10, 4));
      expect(week.every((d) => d.hour == 0), isTrue);
    });

    test('greetingFor', () {
      expect(greetingFor(DateTime(2026, 1, 1, 8)), 'Good morning');
      expect(greetingFor(DateTime(2026, 1, 1, 14)), 'Good afternoon');
      expect(greetingFor(DateTime(2026, 1, 1, 21)), 'Good evening');
    });
  });

  group('statistics', () {
    final now = DateTime(2026, 9, 16, 12); // Wednesday

    test('today window is quarter-day buckets vs yesterday', () {
      final w = windowFor(StatsPeriod.today, now); // noon
      expect(w.current.from, DateTime(2026, 9, 16));
      expect(w.current.to, DateTime(2026, 9, 17));
      expect(w.previous.from, DateTime(2026, 9, 15));
      expect(w.previous.to, DateTime(2026, 9, 16));
      expect(w.buckets.map((b) => b.label), [
        'Night', 'Morning', 'Afternoon', 'Evening', //
      ]);
      expect(w.buckets[2].isCurrent(now), isTrue); // noon falls in Afternoon
      expect(w.buckets[3].isFuture(now), isTrue); // Evening hasn't started
    });

    test('week window is Mon–Sun with 7 daily buckets', () {
      final w = windowFor(StatsPeriod.week, now);
      expect(w.current.from, DateTime(2026, 9, 14));
      expect(w.current.to, DateTime(2026, 9, 21));
      expect(w.previous.from, DateTime(2026, 9, 7));
      expect(w.buckets.map((b) => b.label), [
        'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun', //
      ]);
    });

    test('month buckets cover every day, last one is short', () {
      final w = windowFor(StatsPeriod.month, now); // September: 30 days
      expect(w.buckets.map((b) => b.label), ['W1', 'W2', 'W3', 'W4', 'W5']);
      expect(w.buckets.last.range.from, DateTime(2026, 9, 29));
      expect(w.buckets.last.range.to, DateTime(2026, 10));

      final feb = windowFor(StatsPeriod.month, DateTime(2026, 2, 10));
      expect(feb.buckets, hasLength(4)); // 28 days
      expect(feb.buckets.last.range.to, DateTime(2026, 3));
    });

    test('6M and year are rolling, ending this month', () {
      final six = windowFor(StatsPeriod.sixMonths, now);
      expect(six.buckets.map((b) => b.label).first, 'Apr');
      expect(six.buckets.map((b) => b.label).last, 'Sep');
      expect(six.previous.from, DateTime(2025, 10));

      final year = windowFor(StatsPeriod.year, now);
      expect(year.buckets, hasLength(12));
      expect(year.current.from, DateTime(2025, 10));
    });

    test('stats: totals, average over elapsed buckets, insights', () async {
      final all = await seed([
        ('Food & Drinks', 'Coffee', 500, DateTime(2026, 9, 14, 8)), // Mon
        ('Transport', 'Taxi', 3000, DateTime(2026, 9, 16, 8)), // Wed
        ('Transport', 'Bus', 1000, DateTime(2026, 9, 9)), // last week
      ]);
      final w = windowFor(StatsPeriod.week, now);
      final stats = buildPeriodStats(StatsPeriod.week, w, all, now);

      expect(stats.totalCents, 3500);
      expect(stats.previousTotalCents, 1000);
      expect(stats.deltaPercent, 250);
      expect(stats.averageCents, 3500 ~/ 3); // Mon, Tue, Wed elapsed
      expect(stats.highest!.label, 'Wed');
      expect(stats.lowest!.label, 'Tue'); // 0, and not a future day
      expect(stats.buckets[2].isCurrent(now), isTrue);
      expect(stats.buckets[3].isFuture(now), isTrue);
      expect(stats.categories.first.category.name, 'Transport');
      expect(stats.categories.first.deltaPercent, 200);
    });
  });
}
