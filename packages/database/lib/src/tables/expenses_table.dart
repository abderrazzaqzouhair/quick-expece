import 'package:drift/drift.dart';

import 'common_columns.dart';
import 'subcategories_table.dart';

/// Mirrors Laravel's `expenses` table, minus `user_id` (single user on the
/// device). The category is reached through the subcategory, as on the server.
@DataClassName('ExpenseRow')
@TableIndex(
  name: 'expenses_date_created_at_index',
  columns: {#date, #createdAt},
)
@TableIndex(name: 'expenses_subcategory_id_index', columns: {#subcategoryId})
class Expenses extends Table with UuidPrimaryKey, Timestamps {
  /// Restrict: a subcategory that still has expenses can't be deleted —
  /// deactivate it instead (same as the server).
  TextColumn get subcategoryId =>
      text().references(Subcategories, #id, onDelete: KeyAction.restrict)();

  /// Amount in cents (12.50 → 1250). SQLite has no exact DECIMAL type, and
  /// doubles would drift when summed. Bounds match the server's validation:
  /// `gt:0`, `max:99999999.99`.
  // ignore: recursive_getters — drift's documented way to reference the column.
  IntColumn get amountCents => integer().check(
    // ignore: recursive_getters
    amountCents.isBiggerThanValue(0) &
        // ignore: recursive_getters
        amountCents.isSmallerOrEqualValue(9999999999),
  )();

  TextColumn get note => text().withLength(max: 1000).nullable()();

  /// When the expense happened (not when it was recorded — see `createdAt`).
  DateTimeColumn get date => dateTime()();
}
