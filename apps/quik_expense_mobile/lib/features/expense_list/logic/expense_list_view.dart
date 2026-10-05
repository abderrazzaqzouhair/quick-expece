import 'package:database/database.dart';
import 'package:flutter/foundation.dart';

import '../../../shared/formatters.dart';
import '../../../shared/spending.dart';
import '../../statistics/logic/period_stats.dart';

export '../../../shared/spending.dart' show CategorySpend;

/// How the list is ordered. Amount-sorted views don't group by day — the
/// grouping would scramble the very order the user asked for.
enum ExpenseSort {
  dateDesc('Newest first'),
  dateAsc('Oldest first'),
  amountDesc('Highest amount'),
  amountAsc('Lowest amount');

  const ExpenseSort(this.label);
  final String label;

  bool get isByDate => this == dateDesc || this == dateAsc;
}

/// User-chosen filters on the expense list screen.
@immutable
class ExpenseListFilters {
  const ExpenseListFilters({
    required this.period,
    this.categoryId,
    this.query = '',
    this.sort = ExpenseSort.dateDesc,
  });

  final StatsPeriod period;
  final String? categoryId;
  final String query;
  final ExpenseSort sort;

  bool get isFiltered => categoryId != null || query.isNotEmpty;
}

/// One day's section in the list — same shape as History's `DayGroup`.
@immutable
class ExpenseDayGroup {
  const ExpenseDayGroup({
    required this.day,
    required this.totalCents,
    required this.items,
  });

  final DateTime day;
  final int totalCents;
  final List<ExpenseDetails> items;
}

/// Everything the expense list screen renders for one page load.
@immutable
class ExpenseListView {
  const ExpenseListView({
    required this.periodCount,
    required this.categories,
    required this.groups,
    required this.flatItems,
    required this.filteredTotalCents,
    required this.filteredCount,
    required this.visibleCount,
  });

  /// How many expenses exist in the whole period, before any filter.
  final int periodCount;

  /// Unfiltered — for the category chip bar.
  final List<CategorySpend> categories;

  /// Populated when the sort is date-based; empty otherwise.
  final List<ExpenseDayGroup> groups;

  /// Populated when the sort is amount-based; empty otherwise.
  final List<ExpenseDetails> flatItems;

  final int filteredTotalCents;
  final int filteredCount;
  final int visibleCount;

  /// The period has no expenses at all.
  bool get isEmptyPeriod => periodCount == 0;

  /// The period has data, but the active filters match nothing.
  bool get isEmptyFiltered => !isEmptyPeriod && filteredCount == 0;

  bool get hasMore => visibleCount < filteredCount;
}

/// [periodExpenses] must already be scoped to the chosen period (see
/// `windowFor` in period_stats.dart) and ordered newest-first.
ExpenseListView buildExpenseListView(
  List<ExpenseDetails> periodExpenses,
  ExpenseListFilters filters, {
  required int visibleCount,
  Set<String> hiddenIds = const {},
}) {
  final visible = [
    for (final e in periodExpenses)
      if (!hiddenIds.contains(e.expense.id)) e,
  ];

  final query = filters.query.trim().toLowerCase();
  final filtered = visible.where((e) {
    if (filters.categoryId != null && e.category.id != filters.categoryId) {
      return false;
    }
    if (query.isEmpty) return true;
    return e.subcategory.name.toLowerCase().contains(query) ||
        e.category.name.toLowerCase().contains(query) ||
        (e.expense.note?.toLowerCase().contains(query) ?? false);
  }).toList();

  switch (filters.sort) {
    case ExpenseSort.dateDesc:
      break; // Already newest-first.
    case ExpenseSort.dateAsc:
      filtered.sort((a, b) => a.expense.date.compareTo(b.expense.date));
    case ExpenseSort.amountDesc:
      filtered.sort(
        (a, b) => b.expense.amountCents.compareTo(a.expense.amountCents),
      );
    case ExpenseSort.amountAsc:
      filtered.sort(
        (a, b) => a.expense.amountCents.compareTo(b.expense.amountCents),
      );
  }

  final filteredTotal = filtered.fold(
    0,
    (sum, e) => sum + e.expense.amountCents,
  );
  final page = filtered.take(visibleCount).toList();

  var groups = const <ExpenseDayGroup>[];
  var flatItems = const <ExpenseDetails>[];
  if (filters.sort.isByDate) {
    final byDay = <DateTime, List<ExpenseDetails>>{};
    for (final e in page) {
      byDay.putIfAbsent(dateOnly(e.expense.date), () => []).add(e);
    }
    groups = [
      for (final MapEntry(key: day, value: items) in byDay.entries)
        ExpenseDayGroup(
          day: day,
          totalCents: items.fold(0, (sum, e) => sum + e.expense.amountCents),
          items: items,
        ),
    ];
  } else {
    flatItems = page;
  }

  return ExpenseListView(
    periodCount: visible.length,
    categories: categoryTotals(visible),
    groups: groups,
    flatItems: flatItems,
    filteredTotalCents: filteredTotal,
    filteredCount: filtered.length,
    visibleCount: page.length,
  );
}
