import 'package:drift/drift.dart';

import '../app_database.dart';
import '../models/query_models.dart';
import '../tables/categories_table.dart';
import '../tables/expenses_table.dart';
import '../tables/subcategories_table.dart';

part 'expenses_dao.g.dart';

/// All date ranges are half-open: `from` inclusive, `to` exclusive — so
/// "this month" is `from: DateTime(y, m)`, `to: DateTime(y, m + 1)`.
@DriftAccessor(tables: [Expenses, Subcategories, Categories])
class ExpensesDao extends DatabaseAccessor<AppDatabase>
    with _$ExpensesDaoMixin {
  ExpensesDao(super.attachedDatabase);

  // ---------------------------------------------------------------- writes

  Future<ExpenseRow> add({
    required String subcategoryId,
    required int amountCents,
    required DateTime date,
    String? note,
  }) => into(expenses).insertReturning(
    ExpensesCompanion.insert(
      subcategoryId: subcategoryId,
      amountCents: amountCents,
      date: date,
      note: Value(note),
    ),
  );

  /// Partial update — only the given fields change. Pass `note: Value(null)`
  /// to clear the note.
  Future<void> edit(
    String id, {
    String? subcategoryId,
    int? amountCents,
    DateTime? date,
    Value<String?> note = const Value.absent(),
  }) => (update(expenses)..where((e) => e.id.equals(id))).write(
    ExpensesCompanion(
      subcategoryId: Value.absentIfNull(subcategoryId),
      amountCents: Value.absentIfNull(amountCents),
      date: Value.absentIfNull(date),
      note: note,
      updatedAt: Value(DateTime.now()),
    ),
  );

  /// Soft delete — the row stays so the deletion can be synced later.
  Future<void> softDelete(String id) => _setDeletedAt(id, DateTime.now());

  Future<void> restore(String id) => _setDeletedAt(id, null);

  Future<void> _setDeletedAt(String id, DateTime? deletedAt) =>
      (update(expenses)..where((e) => e.id.equals(id))).write(
        ExpensesCompanion(
          deletedAt: Value(deletedAt),
          updatedAt: Value(DateTime.now()),
        ),
      );

  // ----------------------------------------------------------------- reads

  /// Non-deleted expenses with their subcategory and category, newest first.
  Stream<List<ExpenseDetails>> watchDetails({
    DateTime? from,
    DateTime? to,
    String? categoryId,
    String? subcategoryId,
  }) {
    final query =
        select(expenses).join([
            innerJoin(
              subcategories,
              subcategories.id.equalsExp(expenses.subcategoryId),
            ),
            innerJoin(
              categories,
              categories.id.equalsExp(subcategories.categoryId),
            ),
          ])
          ..where(
            _filter(from: from, to: to, subcategoryId: subcategoryId) &
                (categoryId == null
                    ? const Constant(true)
                    : categories.id.equals(categoryId)),
          )
          ..orderBy([
            OrderingTerm.desc(expenses.date),
            OrderingTerm.desc(expenses.createdAt),
          ]);

    return query.watch().map(
      (rows) => [
        for (final row in rows)
          ExpenseDetails(
            expense: row.readTable(expenses),
            subcategory: row.readTable(subcategories),
            category: row.readTable(categories),
          ),
      ],
    );
  }

  Future<ExpenseRow?> findById(String id) =>
      (select(expenses)..where((e) => e.id.equals(id))).getSingleOrNull();

  /// Total spent (in cents) over the period.
  Stream<int> watchTotal({DateTime? from, DateTime? to}) {
    final total = expenses.amountCents.sum();
    final query = selectOnly(expenses)
      ..addColumns([total])
      ..where(_filter(from: from, to: to));
    return query.watchSingle().map((row) => row.read(total) ?? 0);
  }

  /// Per-category totals over the period, biggest first. Categories with no
  /// expenses in the period are omitted.
  Stream<List<CategoryTotal>> watchTotalsByCategory({
    DateTime? from,
    DateTime? to,
  }) {
    final total = expenses.amountCents.sum();
    final count = expenses.id.count();
    final query =
        select(expenses).join([
            innerJoin(
              subcategories,
              subcategories.id.equalsExp(expenses.subcategoryId),
              useColumns: false,
            ),
            innerJoin(
              categories,
              categories.id.equalsExp(subcategories.categoryId),
            ),
          ])
          ..addColumns([total, count])
          ..where(_filter(from: from, to: to))
          ..groupBy([categories.id])
          ..orderBy([OrderingTerm.desc(total)]);

    return query.watch().map(
      (rows) => [
        for (final row in rows)
          CategoryTotal(
            category: row.readTable(categories),
            totalCents: row.read(total) ?? 0,
            count: row.read(count) ?? 0,
          ),
      ],
    );
  }

  Expression<bool> _filter({
    DateTime? from,
    DateTime? to,
    String? subcategoryId,
  }) {
    Expression<bool> where = expenses.deletedAt.isNull();
    if (from != null) where &= expenses.date.isBiggerOrEqualValue(from);
    if (to != null) where &= expenses.date.isSmallerThanValue(to);
    if (subcategoryId != null) {
      where &= expenses.subcategoryId.equals(subcategoryId);
    }
    return where;
  }
}
