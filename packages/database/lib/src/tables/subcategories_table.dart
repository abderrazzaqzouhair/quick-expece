import 'package:drift/drift.dart';

import 'categories_table.dart';
import 'common_columns.dart';

/// Mirrors Laravel's `subcategories` table, minus `icon`. `isSelected`
/// replaces the server's `user_subcategories` pivot.
@DataClassName('SubcategoryRow')
@TableIndex(
  name: 'subcategories_category_id_is_active_index',
  columns: {#categoryId, #isActive},
)
class Subcategories extends Table with UuidPrimaryKey, Timestamps {
  TextColumn get categoryId =>
      text().references(Categories, #id, onDelete: KeyAction.cascade)();

  TextColumn get name => text().withLength(min: 1, max: 255)();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  BoolColumn get isSelected => boolean().withDefault(const Constant(true))();

  /// A subcategory name is unique within its parent category.
  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {categoryId, name},
  ];
}
