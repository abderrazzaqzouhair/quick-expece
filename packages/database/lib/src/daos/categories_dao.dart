import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/categories_table.dart';
import '../tables/subcategories_table.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [Categories, Subcategories])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.attachedDatabase);

  /// Active, non-deleted categories ordered by name. With [onlySelected],
  /// only the ones the user chose to show.
  Stream<List<CategoryRow>> watchAll({bool onlySelected = false}) {
    final query = select(categories)
      ..where(
        (c) =>
            c.isActive.equals(true) &
            c.deletedAt.isNull() &
            (onlySelected ? c.isSelected.equals(true) : const Constant(true)),
      )
      ..orderBy([(c) => OrderingTerm.asc(c.name)]);
    return query.watch();
  }

  Future<CategoryRow?> findById(String id) =>
      (select(categories)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<void> setSelected(String id, {required bool selected}) =>
      (update(categories)..where((c) => c.id.equals(id))).write(
        CategoriesCompanion(
          isSelected: Value(selected),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Makes every category and subcategory visible again.
  Future<void> showAll() => transaction(() async {
    final now = DateTime.now();
    await update(categories).write(
      CategoriesCompanion(isSelected: const Value(true), updatedAt: Value(now)),
    );
    await update(subcategories).write(
      SubcategoriesCompanion(
        isSelected: const Value(true),
        updatedAt: Value(now),
      ),
    );
  });
}
