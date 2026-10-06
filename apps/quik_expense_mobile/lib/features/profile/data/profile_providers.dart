import 'package:database/database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/providers/database_providers.dart';
import '../../../shared/formatters.dart';
import '../../../shared/csv_export.dart';
import 'profile_store.dart';

/// All-time count / total / first date, for the profile header stats.
final expenseSummaryProvider = StreamProvider<ExpenseSummary>(
  (ref) => ref.watch(appDatabaseProvider).expensesDao.watchSummary(),
);

/// Every active category, selected or not (for managing visibility).
final allCategoriesProvider = StreamProvider<List<CategoryRow>>(
  (ref) => ref.watch(appDatabaseProvider).categoriesDao.watchAll(),
);

/// Every active subcategory across all categories.
final allSubcategoriesProvider = StreamProvider<List<SubcategoryRow>>(
  (ref) => ref.watch(appDatabaseProvider).subcategoriesDao.watchAll(),
);

/// Data-management actions behind Settings and Privacy.
final dataActionsProvider = Provider<DataActions>(DataActions.new);

class DataActions {
  DataActions(this._ref);

  final Ref _ref;

  AppDatabase get _db => _ref.read(appDatabaseProvider);

  /// All expenses as CSV (oldest first), ready to paste into a spreadsheet.
  /// Returns the CSV and the row count.
  Future<(String, int)> exportCsv() async {
    final rows = await _db.expensesDao.watchDetails().first;
    return (expensesCsv(rows), rows.length);
  }

  Future<int> deleteAllExpenses() => _db.expensesDao.softDeleteAll();

  Future<void> showAllCategories() => _db.categoriesDao.showAll();

  /// Expenses, category choices, profile and settings back to a fresh
  /// install (the category catalogue itself stays).
  Future<void> eraseEverything() async {
    await deleteAllExpenses();
    await showAllCategories();
    await _ref.read(profileProvider.notifier).reset();
    await _ref.read(settingsProvider.notifier).reset();
  }
}

/// "Tracking for 12 days" style duration since [since].
String trackingDuration(DateTime since) {
  final days = dateOnly(DateTime.now()).difference(dateOnly(since)).inDays;
  if (days < 1) return 'Today';
  if (days < 60) return '$days ${days == 1 ? 'day' : 'days'}';
  final months = days ~/ 30;
  if (months < 24) return '$months months';
  return '${days ~/ 365} years';
}
