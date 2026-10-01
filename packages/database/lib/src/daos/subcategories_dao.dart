import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/subcategories_table.dart';

part 'subcategories_dao.g.dart';

@DriftAccessor(tables: [Subcategories])
class SubcategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$SubcategoriesDaoMixin {
  SubcategoriesDao(super.attachedDatabase);

  /// Active, non-deleted subcategories of [categoryId], ordered by name.
  Stream<List<SubcategoryRow>> watchByCategory(
    String categoryId, {
    bool onlySelected = false,
  }) {
    final query = select(subcategories)
      ..where(
        (s) =>
            s.categoryId.equals(categoryId) &
            s.isActive.equals(true) &
            s.deletedAt.isNull() &
            (onlySelected ? s.isSelected.equals(true) : const Constant(true)),
      )
      ..orderBy([(s) => OrderingTerm.asc(s.name)]);
    return query.watch();
  }

  /// Every active, non-deleted subcategory (all categories), by name.
  Stream<List<SubcategoryRow>> watchAll() {
    final query = select(subcategories)
      ..where((s) => s.isActive.equals(true) & s.deletedAt.isNull())
      ..orderBy([(s) => OrderingTerm.asc(s.name)]);
    return query.watch();
  }

  Future<SubcategoryRow?> findById(String id) =>
      (select(subcategories)..where((s) => s.id.equals(id))).getSingleOrNull();

  Future<void> setSelected(String id, {required bool selected}) =>
      (update(subcategories)..where((s) => s.id.equals(id))).write(
        SubcategoriesCompanion(
          isSelected: Value(selected),
          updatedAt: Value(DateTime.now()),
        ),
      );
}
