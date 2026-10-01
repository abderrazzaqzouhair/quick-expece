import 'package:database/database.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  // One test opens two in-memory databases on purpose (separate executors).
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  String sub(String category, String name) =>
      CatalogueSeeder.subcategoryId(category, name);

  group('seed', () {
    test('creates the Laravel catalogue on first open', () async {
      final categories = await db.categoriesDao.watchAll().first;
      expect(categories, hasLength(12));
      expect(categories.first.name, 'Bills & Financial'); // ordered by name

      final food = await db.subcategoriesDao
          .watchByCategory(CatalogueSeeder.categoryId('Food & Drinks'))
          .first;
      expect(food, hasLength(8));
    });

    test('ids are deterministic across installs', () async {
      final other = AppDatabase(NativeDatabase.memory());
      addTearDown(other.close);
      final a = await db.categoriesDao.watchAll().first;
      final b = await other.categoriesDao.watchAll().first;
      expect(a.map((c) => c.id), b.map((c) => c.id));
    });

    test('re-running keeps user selections', () async {
      final id = CatalogueSeeder.categoryId('Travel');
      await db.categoriesDao.setSelected(id, selected: false);
      await CatalogueSeeder(db).run();

      expect((await db.categoriesDao.findById(id))!.isSelected, isFalse);
      final selected = await db.categoriesDao
          .watchAll(onlySelected: true)
          .first;
      expect(selected.map((c) => c.id), isNot(contains(id)));
    });
  });

  group('expenses', () {
    test('add, edit, soft delete, restore', () async {
      final coffee = sub('Food & Drinks', 'Coffee');
      final e = await db.expensesDao.add(
        subcategoryId: coffee,
        amountCents: 1250,
        date: DateTime(2026, 9, 10),
        note: 'Latte',
      );
      expect(e.id, hasLength(36));

      await db.expensesDao.edit(
        e.id,
        amountCents: 900,
        note: const Value(null),
      );
      final edited = (await db.expensesDao.findById(e.id))!;
      expect(edited.amountCents, 900);
      expect(edited.note, isNull);
      expect(edited.updatedAt.isBefore(e.updatedAt), isFalse);

      await db.expensesDao.softDelete(e.id);
      expect(await db.expensesDao.watchDetails().first, isEmpty);
      expect(await db.expensesDao.findById(e.id), isNotNull); // row kept

      await db.expensesDao.restore(e.id);
      expect(await db.expensesDao.watchDetails().first, hasLength(1));
    });

    test('rejects non-positive amounts and unknown subcategories', () async {
      await expectLater(
        db.expensesDao.add(
          subcategoryId: sub('Transport', 'Bus'),
          amountCents: 0,
          date: DateTime(2026, 9, 1),
        ),
        throwsA(isA<SqliteException>()),
      );
      await expectLater(
        db.expensesDao.add(
          subcategoryId: 'nope',
          amountCents: 100,
          date: DateTime(2026, 9, 1),
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('filters by half-open date range and computes totals', () async {
      final coffee = sub('Food & Drinks', 'Coffee');
      final bus = sub('Transport', 'Bus');
      final taxi = sub('Transport', 'Taxi');

      Future<void> add(String s, int cents, DateTime d) =>
          db.expensesDao.add(subcategoryId: s, amountCents: cents, date: d);

      await add(coffee, 300, DateTime(2026, 8, 31, 23, 59)); // August
      await add(coffee, 450, DateTime(2026, 9, 1)); // Sept start (included)
      await add(bus, 200, DateTime(2026, 9, 15, 8));
      await add(taxi, 1500, DateTime(2026, 9, 30, 22));
      await add(bus, 999, DateTime(2026, 10, 1)); // October (excluded)

      final from = DateTime(2026, 9);
      final to = DateTime(2026, 10);

      final sept = await db.expensesDao.watchDetails(from: from, to: to).first;
      expect(sept.map((d) => d.expense.amountCents), [1500, 200, 450]);
      expect(sept.first.category.name, 'Transport');
      expect(sept.first.subcategory.name, 'Taxi');

      expect(await db.expensesDao.watchTotal(from: from, to: to).first, 2150);

      final byCategory = await db.expensesDao
          .watchTotalsByCategory(from: from, to: to)
          .first;
      expect(byCategory.map((t) => (t.category.name, t.totalCents, t.count)), [
        ('Transport', 1700, 2),
        ('Food & Drinks', 450, 1),
      ]);

      final transportOnly = await db.expensesDao
          .watchDetails(categoryId: CatalogueSeeder.categoryId('Transport'))
          .first;
      expect(transportOnly, hasLength(3));
    });
  });
}
