import 'package:database/database.dart';
import 'package:flutter/foundation.dart';

import '../../../shared/formatters.dart';
import '../../../shared/spending.dart';

export '../../../shared/spending.dart' show CategorySpend;

/// User-chosen filters on the History tab.
@immutable
class HistoryFilters {
  const HistoryFilters({
    required this.month,
    this.categoryId,
    this.day,
    this.query = '',
  });

  /// First day of the shown month.
  final DateTime month;
  final String? categoryId;

  /// A single day inside [month], picked from the daily bars.
  final DateTime? day;
  final String query;

  bool get isFiltered => categoryId != null || day != null || query.isNotEmpty;
}

/// One day's section in the list.
@immutable
class DayGroup {
  const DayGroup({
    required this.day,
    required this.totalCents,
    required this.items,
  });

  final DateTime day;
  final int totalCents;
  final List<ExpenseDetails> items;
}

/// Everything the History screen renders, derived from one month of
/// expenses + [HistoryFilters]. Month-level numbers (total, daily bars,
/// chips) ignore the filters so the overview stays stable while filtering.
@immutable
class HistoryView {
  const HistoryView({
    required this.monthTotalCents,
    required this.monthCount,
    required this.dailyTotals,
    required this.categories,
    required this.groups,
    required this.filteredTotalCents,
    required this.filteredCount,
  });

  final int monthTotalCents;
  final int monthCount;

  /// Index 0 = day 1 of the month.
  final List<int> dailyTotals;
  final List<CategorySpend> categories;
  final List<DayGroup> groups;
  final int filteredTotalCents;
  final int filteredCount;

  bool get isEmptyMonth => monthCount == 0;
}

HistoryView buildHistoryView(
  List<ExpenseDetails> monthExpenses,
  HistoryFilters filters, {
  Set<String> hiddenIds = const {},
}) {
  final visible = [
    for (final e in monthExpenses)
      if (!hiddenIds.contains(e.expense.id)) e,
  ];

  final daysInMonth = DateTime(
    filters.month.year,
    filters.month.month + 1,
    0,
  ).day;
  final daily = List<int>.filled(daysInMonth, 0);
  var monthTotal = 0;

  for (final e in visible) {
    final cents = e.expense.amountCents;
    monthTotal += cents;
    final dayIndex = e.expense.date.day - 1;
    if (dayIndex >= 0 && dayIndex < daysInMonth) daily[dayIndex] += cents;
  }

  final query = filters.query.trim().toLowerCase();
  final filtered = visible.where((e) {
    if (filters.categoryId != null && e.category.id != filters.categoryId) {
      return false;
    }
    if (filters.day != null && dateOnly(e.expense.date) != filters.day) {
      return false;
    }
    if (query.isEmpty) return true;
    return e.subcategory.name.toLowerCase().contains(query) ||
        e.category.name.toLowerCase().contains(query) ||
        (e.expense.note?.toLowerCase().contains(query) ?? false);
  });

  // Input is already newest-first (the DAO orders by date desc), and maps
  // keep insertion order — so days come out newest-first too.
  final byDay = <DateTime, List<ExpenseDetails>>{};
  for (final e in filtered) {
    byDay.putIfAbsent(dateOnly(e.expense.date), () => []).add(e);
  }
  final groups = [
    for (final MapEntry(key: day, value: items) in byDay.entries)
      DayGroup(
        day: day,
        totalCents: items.fold(0, (sum, e) => sum + e.expense.amountCents),
        items: items,
      ),
  ];
  final filteredTotal = groups.fold(0, (sum, g) => sum + g.totalCents);
  final filteredCount = groups.fold(0, (sum, g) => sum + g.items.length);

  return HistoryView(
    monthTotalCents: monthTotal,
    monthCount: visible.length,
    dailyTotals: daily,
    categories: categoryTotals(visible),
    groups: groups,
    filteredTotalCents: filteredTotal,
    filteredCount: filteredCount,
  );
}
