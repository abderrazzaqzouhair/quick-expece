import 'package:database/database.dart';
import 'package:flutter/foundation.dart';

import '../../../shared/formatters.dart';
import '../../../shared/spending.dart';

// ---------------------------------------------------------------- Quick Add

/// How far back Quick Add looks for your habits.
const quickAddLookbackDays = 60;

/// The range Quick Add needs, ending tomorrow so today's entries count.
DateRange quickAddRange(DateTime today) {
  final d = dateOnly(today);
  return (
    from: DateTime(d.year, d.month, d.day - quickAddLookbackDays),
    to: DateTime(d.year, d.month, d.day + 1),
  );
}

/// A one-tap shortcut: a subcategory you use often.
@immutable
class QuickAddItem {
  const QuickAddItem({
    required this.category,
    required this.subcategory,
    required this.count,
  });

  final CategoryRow category;
  final SubcategoryRow subcategory;
  final int count;
}

/// Most-used subcategories (by count), ties broken by most recent use.
/// [expenses] must be newest-first (as the DAO returns them).
List<QuickAddItem> quickAddSuggestions(
  List<ExpenseDetails> expenses, {
  int max = 6,
}) {
  final counts = <String, int>{};
  final firstSeen = <String, int>{}; // index in newest-first list
  final rows = <String, ExpenseDetails>{};
  for (final (i, e) in expenses.indexed) {
    final id = e.subcategory.id;
    counts[id] = (counts[id] ?? 0) + 1;
    firstSeen.putIfAbsent(id, () => i);
    rows.putIfAbsent(id, () => e);
  }
  final ids = counts.keys.toList()
    ..sort((a, b) {
      final byCount = counts[b]!.compareTo(counts[a]!);
      return byCount != 0 ? byCount : firstSeen[a]!.compareTo(firstSeen[b]!);
    });
  return [
    for (final id in ids.take(max))
      QuickAddItem(
        category: rows[id]!.category,
        subcategory: rows[id]!.subcategory,
        count: counts[id]!,
      ),
  ];
}

// ---------------------------------------------------------------- This Week

/// Totals per day for the 7 days starting at [weekStart] (Monday).
List<int> weekTotals(Iterable<ExpenseDetails> expenses, DateTime weekStart) {
  final totals = List<int>.filled(7, 0);
  final start = dateOnly(weekStart);
  for (final e in expenses) {
    final i = dateOnly(e.expense.date).difference(start).inDays;
    if (i >= 0 && i < 7) totals[i] += e.expense.amountCents;
  }
  return totals;
}

// ---------------------------------------------------------------- Insights

enum InsightKind { projection, categoryUp, categoryDown, biggest, noSpendDays }

/// One short, data-backed observation. [highlight] is the part shown bold.
@immutable
class Insight {
  const Insight({
    required this.kind,
    required this.text,
    required this.highlight,
  });

  final InsightKind kind;

  /// Full sentence containing [highlight] once.
  final String text;
  final String highlight;
}

/// Up to [max] insights for the month of [selected], in priority order:
/// end-of-month projection (current month, from day 3), biggest category
/// change vs last month (≥ ±20%), biggest single expense, no-spend days.
///
/// [twoMonths] must cover the selected month and the one before it.
List<Insight> buildInsights(
  List<ExpenseDetails> twoMonths,
  DateTime selected, {
  DateTime? now,
  int max = 3,
}) {
  final today = dateOnly(now ?? DateTime.now());
  final monthStart = DateTime(selected.year, selected.month);
  final nextMonth = DateTime(selected.year, selected.month + 1);
  final thisMonth = inRange(twoMonths, (
    from: monthStart,
    to: nextMonth,
  )).toList();
  final lastMonth = inRange(twoMonths, (
    from: DateTime(selected.year, selected.month - 1),
    to: monthStart,
  )).toList();
  if (thisMonth.isEmpty) return const [];

  final insights = <Insight>[];
  final isCurrentMonth =
      today.year == selected.year && today.month == selected.month;
  final daysInMonth = DateTime(selected.year, selected.month + 1, 0).day;
  final total = sumCents(thisMonth);

  // 1. Projection — only meaningful once a few days have passed.
  if (isCurrentMonth && today.day >= 3 && today.day < daysInMonth) {
    final projected = (total / today.day * daysInMonth).round();
    final value = '~${formatMad(projected)}';
    insights.add(
      Insight(
        kind: InsightKind.projection,
        text: 'At this pace you\'ll spend $value this month',
        highlight: value,
      ),
    );
  }

  // 2. Biggest category change vs last month (both months non-zero).
  final changes =
      categoryTotals(thisMonth, previous: lastMonth)
          .where((c) => c.deltaPercent != null && c.deltaPercent!.abs() >= 20)
          .toList()
        ..sort(
          (a, b) => b.deltaPercent!.abs().compareTo(a.deltaPercent!.abs()),
        );
  if (changes.isNotEmpty) {
    final c = changes.first;
    final up = c.deltaPercent! > 0;
    final value = '${up ? 'up' : 'down'} ${c.deltaPercent!.abs()}%';
    insights.add(
      Insight(
        kind: up ? InsightKind.categoryUp : InsightKind.categoryDown,
        text: '${c.category.name} is $value vs last month',
        highlight: value,
      ),
    );
  }

  // 3. Biggest single expense.
  final biggest = thisMonth.reduce(
    (a, b) => b.expense.amountCents > a.expense.amountCents ? b : a,
  );
  final biggestValue = formatMad(biggest.expense.amountCents);
  insights.add(
    Insight(
      kind: InsightKind.biggest,
      text:
          'Biggest expense: ${biggest.subcategory.name} · $biggestValue '
          '(${formatDayLabel(biggest.expense.date)})',
      highlight: biggestValue,
    ),
  );

  // 4. No-spend days among the days that have passed.
  final lastDay = isCurrentMonth ? today.day : daysInMonth;
  final spentDays = {
    for (final e in thisMonth)
      if (e.expense.date.day <= lastDay) e.expense.date.day,
  };
  final noSpend = lastDay - spentDays.length;
  if (noSpend > 0) {
    final value = '$noSpend no-spend ${noSpend == 1 ? 'day' : 'days'}';
    insights.add(
      Insight(
        kind: InsightKind.noSpendDays,
        text: isCurrentMonth
            ? '$value so far this month — nice'
            : '$value that month',
        highlight: value,
      ),
    );
  }

  return insights.take(max).toList();
}
