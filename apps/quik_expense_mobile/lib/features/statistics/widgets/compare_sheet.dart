import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../../shared/category_visuals.dart';
import '../../../shared/formatters.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/haptics.dart';
import '../../../shared/spending.dart';
import '../../../shared/widgets/pressable.dart';
import '../../add_expense/widgets/date_sheet.dart';
import '../logic/period_compare.dart';
import '../logic/period_stats.dart';

/// "October vs September ▾": both totals with the difference, then every
/// category with paired bars (this period in orange, the other in grey) and
/// its change. The second period defaults to the previous one and can be
/// changed: any past day for Today, any past week / month / range otherwise.
Future<void> showCompareSheet(
  BuildContext context, {
  required StatsPeriod period,
  required PeriodWindow window,
}) {
  return showAppSheet<void>(
    context,
    builder: (_) => _CompareSheet(period: period, window: window),
  );
}

class _CompareSheet extends ConsumerStatefulWidget {
  const _CompareSheet({required this.period, required this.window});

  final StatsPeriod period;
  final PeriodWindow window;

  @override
  ConsumerState<_CompareSheet> createState() => _CompareSheetState();
}

class _CompareSheetState extends ConsumerState<_CompareSheet> {
  static const previousColor = Color(0xFFB8BEC7);

  /// How many periods back the other side is (1 = previous).
  int _offset = 1;

  /// Last computed comparison, kept while a newly picked period loads.
  PeriodComparison? _last;

  DateRange get _other => shiftedRange(widget.period, widget.window, _offset);

  Future<void> _pickOther() async {
    Haptics.selection();
    final now = DateTime.now();
    final int? offset;
    if (widget.period == StatsPeriod.today) {
      final picked = await showDateSheet(context, _other.from);
      if (picked == null) return;
      offset = DateTime.utc(
        now.year,
        now.month,
        now.day,
      ).difference(DateTime.utc(picked.year, picked.month, picked.day)).inDays;
    } else {
      offset = await showAppSheet<int>(
        context,
        builder: (_) => _PeriodPicker(
          period: widget.period,
          window: widget.window,
          selected: _offset,
        ),
      );
    }
    // Comparing a period with itself says nothing — keep the current pick.
    if (offset == null || offset < 1 || !mounted) return;
    setState(() => _offset = offset!);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final other = _other;
    final current = ref.watch(expensesInRangeProvider(widget.window.current));
    final previous = ref.watch(expensesInRangeProvider(other));
    if (current.hasValue && previous.hasValue) {
      _last = compareExpenses(current.value!, previous.value!);
    }
    final c = _last;
    final loading = current.isLoading || previous.isLoading;
    final currentName = rangeName(widget.period, widget.window.current, now);
    final previousName = rangeName(widget.period, other, now);

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Column(
        children: [
          AppSheetHeader(
            title: 'Compare',
            trailing: SheetTextButton(
              label: 'Done',
              isPrimary: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _VsSelector(
              currentName: currentName,
              otherName: previousName,
              onPick: _pickOther,
            ),
          ),
          Expanded(
            child: c == null
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : AnimatedOpacity(
                    opacity: loading ? 0.5 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: _ComparisonBody(
                      comparison: c,
                      currentName: currentName,
                      previousName: previousName,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonBody extends StatelessWidget {
  const _ComparisonBody({
    required this.comparison,
    required this.currentName,
    required this.previousName,
  });

  final PeriodComparison comparison;
  final String currentName;
  final String previousName;

  @override
  Widget build(BuildContext context) {
    final c = comparison;
    final maxCents = c.categories.fold(
      0,
      (m, x) => math.max(m, math.max(x.currentCents, x.previousCents)),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        _TotalsCard(
          currentName: currentName,
          previousName: previousName,
          comparison: c,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'By category',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  _Legend(color: AppColors.primary, label: currentName),
                  const SizedBox(width: 12),
                  _Legend(
                    color: _CompareSheetState.previousColor,
                    label: previousName,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (c.categories.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No expenses in either period.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                for (final row in c.categories)
                  _CategoryRow(row: row, maxCents: maxCents),
            ],
          ),
        ),
      ],
    );
  }
}

/// "October  vs  September ▾" — the second name opens the period picker.
class _VsSelector extends StatelessWidget {
  const _VsSelector({
    required this.currentName,
    required this.otherName,
    required this.onPick,
  });

  final String currentName;
  final String otherName;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              currentName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'vs',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Flexible(
          child: Pressable(
            onTap: onPick,
            semanticLabel: 'Compare with $otherName. Change',
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      otherName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Past weeks / months / ranges to compare with, most recent first.
class _PeriodPicker extends StatelessWidget {
  const _PeriodPicker({
    required this.period,
    required this.window,
    required this.selected,
  });

  final StatsPeriod period;
  final PeriodWindow window;
  final int selected;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final count = comparableCount(period);
    final title = switch (period) {
      StatsPeriod.week => 'Compare with week',
      StatsPeriod.month => 'Compare with month',
      _ => 'Compare with',
    };

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.6,
      child: Column(
        children: [
          AppSheetHeader(
            title: title,
            leading: SheetTextButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: count,
              itemBuilder: (context, i) {
                final offset = i + 1;
                final range = shiftedRange(period, window, offset);
                final isSelected = offset == selected;
                return Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(i == 0 ? 16 : 0),
                    bottom: Radius.circular(i == count - 1 ? 16 : 0),
                  ),
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(offset),
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: i == count - 1
                            ? null
                            : const Border(
                                bottom: BorderSide(
                                  color: AppColors.border,
                                  width: 0.5,
                                ),
                              ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              rangeName(period, range, now),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_rounded,
                              color: AppColors.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({
    required this.currentName,
    required this.previousName,
    required this.comparison,
  });

  final String currentName;
  final String previousName;
  final PeriodComparison comparison;

  @override
  Widget build(BuildContext context) {
    final diff = comparison.differenceCents;
    final delta = comparison.deltaPercent;
    final up = diff > 0;
    final color = diff == 0
        ? AppColors.textSecondary
        : up
        ? const Color(0xFFE5484D)
        : const Color(0xFF16A34A);

    Widget column(String name, int cents, {required bool primary}) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatMad(cents),
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: primary
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              column(currentName, comparison.currentTotalCents, primary: true),
              const SizedBox(width: 12),
              column(
                previousName,
                comparison.previousTotalCents,
                primary: false,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  diff == 0
                      ? Icons.drag_handle_rounded
                      : up
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    diff == 0
                        ? 'Same as $previousName'
                        : '${formatMad(diff.abs())} ${up ? 'more' : 'less'}'
                              '${delta == null ? '' : ' (${delta.abs()}%)'}'
                              ' than $previousName',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
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

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.row, required this.maxCents});

  final CategoryComparison row;
  final int maxCents;

  @override
  Widget build(BuildContext context) {
    final delta = row.deltaPercent;
    final up = row.differenceCents > 0;
    final (String label, Color color) = switch (delta) {
      _ when row.currentCents == 0 => ('Stopped', const Color(0xFF16A34A)),
      null => ('New', CategoryVisuals.colorFor(row.category.color)),
      0 => ('0%', AppColors.textSecondary),
      final d => (
        '${up ? '↑' : '↓'} ${d.abs()}%',
        up ? const Color(0xFFE5484D) : const Color(0xFF16A34A),
      ),
    };

    double fraction(int cents) => maxCents == 0 ? 0 : cents / maxCents;

    return Semantics(
      label:
          '${row.category.name}: ${formatMad(row.currentCents)} now, '
          '${formatMad(row.previousCents)} before',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            CategoryAvatar(
              name: row.category.name,
              colorHex: row.category.color,
              size: 36,
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
                          row.category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _PairedBar(
                    fraction: fraction(row.currentCents),
                    color: AppColors.primary,
                    amount: row.currentCents,
                  ),
                  const SizedBox(height: 4),
                  _PairedBar(
                    fraction: fraction(row.previousCents),
                    color: _CompareSheetState.previousColor,
                    amount: row.previousCents,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A horizontal bar with its amount at the end.
class _PairedBar extends StatelessWidget {
  const _PairedBar({
    required this.fraction,
    required this.color,
    required this.amount,
  });

  final double fraction;
  final Color color;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) => Align(
              alignment: Alignment.centerLeft,
              child: Container(
                height: 8,
                width: amount == 0 ? 4 : math.max(6, fraction * c.maxWidth),
                decoration: BoxDecoration(
                  color: amount == 0 ? color.withValues(alpha: 0.3) : color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 86,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              formatAmount(amount),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 90),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
