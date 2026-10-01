import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../app_database.dart';
import 'category_catalogue.dart';

/// Upserts [categoryCatalogue] — same behaviour as the Laravel
/// `CategorySeeder`:
/// - listed entries are inserted, or have their colour refreshed and are
///   re-activated;
/// - entries no longer listed are deactivated, never deleted, so old
///   expenses keep their references.
///
/// The user's `isSelected` choices are never overwritten.
///
/// Ids are deterministic (UUID v5 of the name), so the same category has the
/// same id on every install — exported backups can be re-imported anywhere.
class CatalogueSeeder {
  const CatalogueSeeder(this._db);

  final AppDatabase _db;

  static const _uuid = Uuid();
  static const _namespace = 'b7c1e3a2-5d4f-4e6a-9c8b-2f1d0e3a4b5c';

  static String categoryId(String name) =>
      _uuid.v5(_namespace, 'category:$name');

  static String subcategoryId(String categoryName, String name) =>
      _uuid.v5(_namespace, 'subcategory:$categoryName/$name');

  Future<void> run() => _db.transaction(() async {
    final now = DateTime.now();
    final categoryIds = <String>[];

    for (final entry in categoryCatalogue) {
      final id = categoryId(entry.name);
      categoryIds.add(id);

      await _db
          .into(_db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: Value(id),
              name: entry.name,
              color: Value(entry.color),
            ),
            onConflict: DoUpdate(
              (_) => CategoriesCompanion(
                color: Value(entry.color),
                isActive: const Value(true),
                updatedAt: Value(now),
              ),
            ),
          );

      final subIds = [
        for (final sub in entry.subcategories) subcategoryId(entry.name, sub),
      ];

      for (final (i, sub) in entry.subcategories.indexed) {
        await _db
            .into(_db.subcategories)
            .insert(
              SubcategoriesCompanion.insert(
                id: Value(subIds[i]),
                categoryId: id,
                name: sub,
              ),
              onConflict: DoUpdate(
                (_) => SubcategoriesCompanion(
                  isActive: const Value(true),
                  updatedAt: Value(now),
                ),
              ),
            );
      }

      // Retire subcategories that fell out of this category's list.
      await (_db.update(
        _db.subcategories,
      )..where((s) => s.categoryId.equals(id) & s.id.isNotIn(subIds))).write(
        SubcategoriesCompanion(
          isActive: const Value(false),
          updatedAt: Value(now),
        ),
      );
    }

    // Retire categories that fell out of the catalogue, with all their
    // subcategories.
    await (_db.update(
      _db.categories,
    )..where((c) => c.id.isNotIn(categoryIds))).write(
      CategoriesCompanion(isActive: const Value(false), updatedAt: Value(now)),
    );
    await (_db.update(
      _db.subcategories,
    )..where((s) => s.categoryId.isNotIn(categoryIds))).write(
      SubcategoriesCompanion(
        isActive: const Value(false),
        updatedAt: Value(now),
      ),
    );
  });
}
