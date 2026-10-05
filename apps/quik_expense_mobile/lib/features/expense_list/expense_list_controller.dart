import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/providers/database_providers.dart';
import '../../shared/spending.dart';
import '../statistics/logic/period_stats.dart';
import 'logic/expense_list_view.dart';

export 'logic/expense_list_view.dart';

const _pageSize = 30;

/// Filters/sort/paging for the expense list screen. Not auto-disposed so an
/// in-progress filter survives a brief detour (e.g. opening an expense's
/// detail sheet), but [openFor] resets everything fresh on every visit.
final expenseListControllerProvider =
    NotifierProvider<ExpenseListController, ExpenseListState>(
      ExpenseListController.new,
    );

@immutable
class ExpenseListState {
  const ExpenseListState({
    required this.filters,
    this.visibleCount = _pageSize,
    this.hiddenIds = const {},
  });

  final ExpenseListFilters filters;
  final int visibleCount;

  /// Expenses swiped away but not yet confirmed gone by the database stream.
  final Set<String> hiddenIds;
}

class ExpenseListController extends Notifier<ExpenseListState> {
  @override
  ExpenseListState build() => const ExpenseListState(
    filters: ExpenseListFilters(period: StatsPeriod.month),
  );

  ExpenseListFilters get _f => state.filters;

  void _setFilters(ExpenseListFilters filters) =>
      state = ExpenseListState(filters: filters, hiddenIds: state.hiddenIds);

  /// Deep-link entry point: called right before pushing the screen, so it
  /// always opens fresh on the given period (and, optionally, a category —
  /// e.g. drilling in from a category card).
  void openFor(StatsPeriod period, {String? categoryId}) =>
      state = ExpenseListState(
        filters: ExpenseListFilters(period: period, categoryId: categoryId),
      );

  void setPeriod(StatsPeriod period) =>
      _setFilters(ExpenseListFilters(period: period, sort: _f.sort));

  /// Tapping the selected category again clears it.
  void toggleCategory(String categoryId) => _setFilters(
    ExpenseListFilters(
      period: _f.period,
      categoryId: _f.categoryId == categoryId ? null : categoryId,
      query: _f.query,
      sort: _f.sort,
    ),
  );

  void setQuery(String query) => _setFilters(
    ExpenseListFilters(
      period: _f.period,
      categoryId: _f.categoryId,
      query: query,
      sort: _f.sort,
    ),
  );

  void setSort(ExpenseSort sort) => _setFilters(
    ExpenseListFilters(
      period: _f.period,
      categoryId: _f.categoryId,
      query: _f.query,
      sort: sort,
    ),
  );

  void clearAll() => _setFilters(ExpenseListFilters(period: _f.period));

  /// Reveals one more page. A deliberate, explicit "Load more" rather than
  /// infinite scroll — keeps a potentially long history from dumping onto
  /// the screen all at once.
  void loadMore() => state = ExpenseListState(
    filters: state.filters,
    visibleCount: state.visibleCount + _pageSize,
    hiddenIds: state.hiddenIds,
  );

  /// Soft-deletes [id], hiding it right away. Returns the undo action.
  Future<Future<void> Function()> delete(String id) async {
    state = ExpenseListState(
      filters: state.filters,
      visibleCount: state.visibleCount,
      hiddenIds: {...state.hiddenIds, id},
    );
    final dao = ref.read(appDatabaseProvider).expensesDao;
    await dao.softDelete(id);
    return () async {
      await dao.restore(id);
      state = ExpenseListState(
        filters: state.filters,
        visibleCount: state.visibleCount,
        hiddenIds: {...state.hiddenIds}..remove(id),
      );
    };
  }
}

/// The rendered view: the selected period's expenses + filters/paging.
final expenseListViewProvider = Provider<AsyncValue<ExpenseListView>>((ref) {
  final state = ref.watch(expenseListControllerProvider);
  final window = windowFor(state.filters.period, DateTime.now());
  return ref
      .watch(expensesInRangeProvider(window.current))
      .whenData(
        (expenses) => buildExpenseListView(
          expenses,
          state.filters,
          visibleCount: state.visibleCount,
          hiddenIds: state.hiddenIds,
        ),
      );
});
