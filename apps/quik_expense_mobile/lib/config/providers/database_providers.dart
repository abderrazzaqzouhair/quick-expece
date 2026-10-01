import 'package:database/database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The single on-device database for the whole app — opened lazily on first
/// read, closed when the `ProviderScope` is disposed. Every screen reaches
/// the data through this (never `AppDatabase()` directly).
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Categories the user chose to show, ordered by name. Live — updates when
/// a category is selected/unselected.
final selectedCategoriesProvider = StreamProvider<List<CategoryRow>>(
  (ref) =>
      ref.watch(appDatabaseProvider).categoriesDao.watchAll(onlySelected: true),
);

/// Selected subcategories of one category, ordered by name.
final selectedSubcategoriesProvider =
    StreamProvider.family<List<SubcategoryRow>, String>(
      (ref, categoryId) => ref
          .watch(appDatabaseProvider)
          .subcategoriesDao
          .watchByCategory(categoryId, onlySelected: true),
    );
