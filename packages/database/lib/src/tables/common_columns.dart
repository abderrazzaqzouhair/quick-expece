import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// New random UUID v4. Public because drift's generated code calls it.
String newId() => _uuid.v4();

/// UUID primary key, generated on the device. Mirrors Laravel's
/// `$table->uuid('id')->primary()` so rows created offline never collide
/// with server ids when sync is added.
mixin UuidPrimaryKey on Table {
  TextColumn get id => text().clientDefault(newId)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// `$table->timestamps()` + `$table->softDeletes()`.
///
/// Rows are soft-deleted (never removed) so a deletion made offline can still
/// be pushed to the server later. `updatedAt` is bumped by the DAOs on every
/// write — SQLite has no `ON UPDATE CURRENT_TIMESTAMP`.
mixin Timestamps on Table {
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}
