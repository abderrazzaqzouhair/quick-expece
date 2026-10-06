import 'package:database/database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../../shared/category_visuals.dart';
import '../../../shared/formatters.dart';
import '../logic/period_details.dart';

const _titleStyle = TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.w700,
  color: AppColors.textPrimary,
);

/// Ranked subcategories with a share bar in the category colour.
class TopSubcategoriesSection extends StatelessWidget {
  const TopSubcategoriesSection({
    super.key,
    required this.items,
    required this.totalCents,
  });

  final List<SubcategorySpend> items;
  final int totalCents;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Top Subcategories', style: _titleStyle),
        const SizedBox(height: 16),
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          _SubcategoryRow(
            rank: i + 1,
            item: items[i],
            share: totalCents == 0 ? 0 : items[i].totalCents / totalCents,
          ),
        ],
      ],
    );
  }
}

class _SubcategoryRow extends StatelessWidget {
  const _SubcategoryRow({
    required this.rank,
    required this.item,
    required this.share,
  });

  final int rank;
  final SubcategorySpend item;
  final double share;

  @override
  Widget build(BuildContext context) {
    final color = CategoryVisuals.colorFor(item.category.color);
    return Semantics(
      label:
          '$rank. ${item.subcategory.name}, ${formatMad(item.totalCents)}, '
          '${item.count} ${item.count == 1 ? 'expense' : 'expenses'}',
      excludeSemantics: true,
      child: Row(
        children: [
          CategoryAvatar(
            name: item.category.name,
            colorHex: item.category.color,
            size: 38,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.subcategory.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Shrinks for huge amounts / large text.
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          formatMad(item.totalCents),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.category.name} · ${item.count}×',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: share.clamp(0.0, 1.0),
                    minHeight: 6,
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Counts and patterns: four figures plus average spend per weekday.
class SpendingHabitsSection extends StatelessWidget {
  const SpendingHabitsSection({super.key, required this.details});

  final PeriodDetails details;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _dayNames = [
    'Mondays',
    'Tuesdays',
    'Wednesdays',
    'Thursdays',
    'Fridays',
    'Saturdays',
    'Sundays',
  ];

  @override
  Widget build(BuildContext context) {
    final d = details;
    final frequent = d.mostFrequent;
    final top = d.topWeekday;
    final maxAvg = d.weekdayAverages.fold(0, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Spending Habits', style: _titleStyle),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.1,
          children: [
            _Metric(
              icon: Icons.receipt_long_rounded,
              color: const Color(0xFF3B82F6),
              value: '${d.count}',
              label: d.count == 1 ? 'Expense' : 'Expenses',
            ),
            _Metric(
              icon: Icons.payments_rounded,
              color: AppColors.primary,
              value: formatAmount(d.averageExpenseCents),
              label: 'Avg per expense',
            ),
            _Metric(
              icon: Icons.self_improvement_rounded,
              color: const Color(0xFF16A34A),
              value: '${d.noSpendDays} of ${d.elapsedDays}',
              label: 'No-spend days',
            ),
            _Metric(
              icon: Icons.repeat_rounded,
              color: const Color(0xFF8B5CF6),
              value: frequent == null ? '—' : frequent.subcategory.name,
              label: frequent == null
                  ? 'Most used'
                  : 'Most used · ${frequent.count}×',
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          top == null
              ? 'Average per weekday'
              : 'You spend most on ${_dayNames[top]}',
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 96,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Semantics(
                    label:
                        '${_dayNames[i]}: average '
                        '${formatMad(d.weekdayAverages[i])}',
                    excludeSemantics: true,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, c) => Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: 22,
                                height: d.weekdayAverages[i] == 0 || maxAvg == 0
                                    ? 5
                                    : (d.weekdayAverages[i] /
                                              maxAvg *
                                              c.maxHeight)
                                          .clamp(8.0, c.maxHeight),
                                decoration: BoxDecoration(
                                  color: i == top
                                      ? AppColors.primary
                                      : AppColors.primary.withValues(
                                          alpha: d.weekdayAverages[i] == 0
                                              ? 0.08
                                              : 0.22,
                                        ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _days[i].substring(0, 1),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: i == top
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: i == top
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The biggest single expenses of the period; tap one for details.
class LargestExpensesSection extends StatelessWidget {
  const LargestExpensesSection({
    super.key,
    required this.expenses,
    required this.onTap,
  });

  final List<ExpenseDetails> expenses;
  final ValueChanged<ExpenseDetails> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Largest Expenses', style: _titleStyle),
        const SizedBox(height: 8),
        for (final e in expenses)
          Semantics(
            button: true,
            label:
                '${e.subcategory.name}, ${formatMad(e.expense.amountCents)}, '
                '${formatDayLabel(e.expense.date)}',
            excludeSemantics: true,
            child: InkWell(
              onTap: () => onTap(e),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    CategoryAvatar(
                      name: e.category.name,
                      colorHex: e.category.color,
                      size: 38,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.subcategory.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${e.expense.note ?? e.category.name} · '
                            '${_dateLabel(e.expense.date)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          formatMad(e.expense.amountCents),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  static String _dateLabel(DateTime date) {
    final day = formatDayLabel(date);
    return day == 'Today' || day == 'Yesterday'
        ? day
        : DateFormat.MMMd('en_US').format(date);
  }
}
