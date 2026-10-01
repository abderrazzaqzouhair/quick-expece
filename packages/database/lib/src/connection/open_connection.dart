import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// Name of the SQLite file (`quik_expense.sqlite` in the app's documents
/// directory on Android/iOS).
const databaseName = 'quik_expense';

/// Opens the on-device database file in a background isolate.
QueryExecutor openConnection() => driftDatabase(name: databaseName);
