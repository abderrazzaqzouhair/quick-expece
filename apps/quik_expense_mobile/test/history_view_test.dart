import 'package:database/database.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quik_expense_mobile/features/history/logic/history_view.dart';

void main() {
  late AppDatabase db;
  late List<ExpenseDetails> september;

  final sept = DateTime(2026, 9);
  String sub(String c, String s) => CatalogueSeeder.subcategoryId(c, s);

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final dao = db.expensesDao;
    await dao.add(
      subcategoryId: sub('Food & Drinks', 'Coffee'),
      amountCents: 450,
      date: DateTime(2026, 9, 1, 8),
      note: 'Latte with Sara',
    );
    await dao.add(
      subcategoryId: sub('Transport', 'Taxi'),
      amountCents: 3000,
      date: DateTime(2026, 9, 1, 19),
    );
    await dao.add(
      subcategoryId: sub('Transport', 'Bus'),
      amountCents: 600,
      date: DateTime(2026, 9, 15, 9),
    );
    september = await dao
        .watchDetails(from: sept, to: DateTime(2026, 10))
        .first;
  });

  tearDown(() => db.close());

  test('month totals, daily bars and category ranking', () {
    final view = buildHistoryView(september, HistoryFilters(month: sept));

    expect(view.monthTotalCents, 4050);
    expect(view.monthCount, 3);
    expect(view.dailyTotals, hasLength(30));
    expect(view.dailyTotals[0], 3450);
    expect(view.dailyTotals[14], 600);
    expect(view.categories.map((c) => (c.category.name, c.totalCents)), [
      ('Transport', 3600),
      ('Food & Drinks', 450),
    ]);
  });

  test('groups by day, newest first, with day totals', () {
    final view = buildHistoryView(september, HistoryFilters(month: sept));

    expect(view.groups.map((g) => (g.day, g.totalCents, g.items.length)), [
      (DateTime(2026, 9, 15), 600, 1),
      (DateTime(2026, 9, 1), 3450, 2),
    ]);
    // Within a day: latest first.
    expect(view.groups.last.items.first.subcategory.name, 'Taxi');
  });

  test('filters narrow the list but not the month overview', () {
    final transportId = CatalogueSeeder.categoryId('Transport');
    final view = buildHistoryView(
      september,
      HistoryFilters(month: sept, categoryId: transportId),
    );
    expect(view.filteredCount, 2);
    expect(view.filteredTotalCents, 3600);
    expect(view.monthTotalCents, 4050); // unchanged

    final byDay = buildHistoryView(
      september,
      HistoryFilters(month: sept, day: DateTime(2026, 9, 1)),
    );
    expect(byDay.filteredCount, 2);

    final search = buildHistoryView(
      september,
      HistoryFilters(month: sept, query: 'sara'),
    );
    expect(search.filteredCount, 1);
    expect(search.groups.single.items.single.subcategory.name, 'Coffee');

    final none = buildHistoryView(
      september,
      HistoryFilters(month: sept, query: 'zzz'),
    );
    expect(none.groups, isEmpty);
  });

  test('hidden (just-deleted) expenses disappear everywhere', () {
    final taxiId = september
        .firstWhere((e) => e.subcategory.name == 'Taxi')
        .expense
        .id;
    final view = buildHistoryView(
      september,
      HistoryFilters(month: sept),
      hiddenIds: {taxiId},
    );
    expect(view.monthTotalCents, 1050);
    expect(view.dailyTotals[0], 450);
  });
}
