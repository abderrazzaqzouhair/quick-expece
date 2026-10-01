import 'package:drift/drift.dart';

import 'connection/open_connection.dart';
import 'daos/categories_dao.dart';
import 'daos/expenses_dao.dart';
import 'daos/subcategories_dao.dart';
import 'seed/catalogue_seeder.dart';
import 'tables/categories_table.dart';
import 'tables/common_columns.dart';
import 'tables/expenses_table.dart';
import 'tables/subcategories_table.dart';

part 'app_database.g.dart';

/// The on-device database. Create ONE instance for the whole app and close
/// it on shutdown.
///
/// Access data through the DAOs: [categoriesDao], [subcategoriesDao],
/// [expensesDao].
@DriftDatabase(
  tables: [Categories, Subcategories, Expenses],
  daos: [CategoriesDao, SubcategoriesDao, ExpensesDao],
)
class AppDatabase extends _$AppDatabase {
  /// Opens the real database file. Pass an [executor] (e.g.
  /// `NativeDatabase.memory()`) to use an in-memory database in tests.
  AppDatabase([QueryExecutor? executor]) : super(executor ?? openConnection());

  /// Bump when a table changes, and add the step to [MigrationStrategy.onUpgrade].
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      // SQLite ignores REFERENCES/ON DELETE unless this is on, per connection.
      await customStatement('PRAGMA foreign_keys = ON');

      // Seed on first launch, and re-sync the catalogue after every upgrade.
      if (details.wasCreated || details.hadUpgrade) {
        await CatalogueSeeder(this).run();
      }
    },
  );
}
