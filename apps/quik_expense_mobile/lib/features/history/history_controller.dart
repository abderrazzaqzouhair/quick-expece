import 'package:database/database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/providers/database_providers.dart';
import '../../shared/formatters.dart';
import 'logic/history_view.dart';

/// Filters + optimistic deletes for the History tab. Not auto-disposed, so
/// the chosen month/filter survives switching tabs.
final historyControllerProvider =
    NotifierProvider<HistoryController, HistoryState>(HistoryController.new);

class HistoryState {
  const HistoryState({required this.filters, this.hiddenIds = const {}});

  final HistoryFilters filters;

  /// Expenses swiped away but not yet confirmed gone by the database stream —
  /// hidden immediately so the list never shows a dismissed row.
  final Set<String> hiddenIds;
}

class HistoryController extends Notifier<HistoryState> {
  @override
  HistoryState build() {
    final now = DateTime.now();
    return HistoryState(
      filters: HistoryFilters(month: DateTime(now.year, now.month)),
    );
  }

  HistoryFilters get _f => state.filters;

  void _setFilters(HistoryFilters filters) =>
      state = HistoryState(filters: filters, hiddenIds: state.hiddenIds);

  bool get canGoForward {
    final now = DateTime.now();
    return _f.month.isBefore(DateTime(now.year, now.month));
  }

  /// Moves by [delta] months; clears the day filter (it belonged to the old
  /// month) but keeps category + search.
  void shiftMonth(int delta) {
    if (delta > 0 && !canGoForward) return;
    _setFilters(
      HistoryFilters(
        month: DateTime(_f.month.year, _f.month.month + delta),
        categoryId: _f.categoryId,
        query: _f.query,
      ),
    );
  }

  /// Tapping the selected category again clears it.
  void toggleCategory(String categoryId) => _setFilters(
    HistoryFilters(
      month: _f.month,
      categoryId: _f.categoryId == categoryId ? null : categoryId,
      day: _f.day,
      query: _f.query,
    ),
  );

  void clearCategory() => _setFilters(
    HistoryFilters(month: _f.month, day: _f.day, query: _f.query),
  );

  /// Tapping the selected day again clears it.
  void toggleDay(DateTime day) {
    final d = dateOnly(day);
    _setFilters(
      HistoryFilters(
        month: _f.month,
        categoryId: _f.categoryId,
        day: _f.day == d ? null : d,
        query: _f.query,
      ),
    );
  }

  void clearDay() => _setFilters(
    HistoryFilters(month: _f.month, categoryId: _f.categoryId, query: _f.query),
  );

  void setQuery(String query) => _setFilters(
    HistoryFilters(
      month: _f.month,
      categoryId: _f.categoryId,
      day: _f.day,
      query: query,
    ),
  );

  void clearAll() => _setFilters(HistoryFilters(month: _f.month));

  /// Deep-link from elsewhere (e.g. a Home category card): show [month]
  /// filtered to [categoryId], clearing any other filter.
  void showCategory(DateTime month, String categoryId) => _setFilters(
    HistoryFilters(
      month: DateTime(month.year, month.month),
      categoryId: categoryId,
    ),
  );

  /// Soft-deletes [id], hiding it right away. Returns the undo action.
  Future<Future<void> Function()> delete(String id) async {
    state = HistoryState(
      filters: state.filters,
      hiddenIds: {...state.hiddenIds, id},
    );
    final dao = ref.read(appDatabaseProvider).expensesDao;
    await dao.softDelete(id);
    return () async {
      await dao.restore(id);
      state = HistoryState(
        filters: state.filters,
        hiddenIds: {...state.hiddenIds}..remove(id),
      );
    };
  }
}

/// One month of expenses (newest first), live.
final monthExpensesProvider =
    StreamProvider.family<List<ExpenseDetails>, DateTime>(
      (ref, month) => ref
          .watch(appDatabaseProvider)
          .expensesDao
          .watchDetails(from: month, to: DateTime(month.year, month.month + 1)),
    );

/// The rendered view: month data + filters.
final historyViewProvider = Provider<AsyncValue<HistoryView>>((ref) {
  final state = ref.watch(historyControllerProvider);
  return ref
      .watch(monthExpensesProvider(state.filters.month))
      .whenData(
        (expenses) => buildHistoryView(
          expenses,
          state.filters,
          hiddenIds: state.hiddenIds,
        ),
      );
});
