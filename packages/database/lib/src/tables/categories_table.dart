import 'package:drift/drift.dart';

import 'common_columns.dart';

/// Global category catalogue — mirrors Laravel's `categories` table, minus
/// `icon`.
///
/// `isSelected` replaces the server's `user_categories` pivot: there is only
/// one user on the device, so "the user picked this category" is a flag.
@DataClassName('CategoryRow')
@TableIndex(name: 'categories_is_active_index', columns: {#isActive})
class Categories extends Table with UuidPrimaryKey, Timestamps {
  TextColumn get name => text().withLength(min: 1, max: 255).unique()();

  /// Hex colour, e.g. `#F59E0B`.
  TextColumn get color => text().withLength(min: 7, max: 9).nullable()();

  /// Catalogue-level visibility (retired entries stay for old expenses).
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Whether the user shows this category in their pickers/lists.
  BoolColumn get isSelected => boolean().withDefault(const Constant(true))();
}
