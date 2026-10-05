import 'package:database/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../config/router/app_routes.dart';
import '../../shared/category_visuals.dart';
import '../../shared/formatters.dart';
import '../../shared/haptics.dart';
import '../../shared/spending.dart';
import '../expense_list/expense_list_controller.dart';
import '../history/widgets/history_empty_state.dart';
import '../statistics/logic/period_stats.dart';

/// This month's categories, biggest spend first, each with a trend vs last
/// month — live from the local database. Tapping a category opens the
/// expense list filtered to it.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final window = windowFor(StatsPeriod.month, DateTime.now());
    final data = ref.watch(expensesInRangeProvider(window.loadRange));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: switch (data) {
        AsyncValue(hasValue: false, hasError: false) => const _Loading(),
        AsyncValue(hasError: true) => const Center(
          child: Text(
            'Could not load your categories.',
            style: TextStyle(color: AppColors.error),
          ),
        ),
        _ => _Content(
          current: inRange(data.value!, window.current).toList(),
          previous: inRange(data.value!, window.previous),
        ),
      },
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.current, required this.previous});

  final List<ExpenseDetails> current;
  final Iterable<ExpenseDetails> previous;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (current.isEmpty) {
      return HistoryEmptyState(
        icon: Icons.category_rounded,
        title: 'No expenses this month',
        message: 'Add an expense and its category will show up here.',
        actionLabel: 'Add expense',
        onAction: () => context.push(AppRoutes.addExpense),
      );
    }

    final categories = categoryTotals(current, previous: previous);
    final total = sumCents(current);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _TotalSpendCard(totalCents: total),
        const SizedBox(height: 24),
        for (final spend in categories)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CategoryListTile(
              spend: spend,
              shareOfTotal: total == 0 ? 0 : spend.totalCents / total,
              onTap: () {
                Haptics.selection();
                ref
                    .read(expenseListControllerProvider.notifier)
                    .openFor(StatsPeriod.month, categoryId: spend.category.id);
                context.push(AppRoutes.expenses);
              },
            ),
          ),
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        AppSkeleton.onDark(
          child: Container(
            height: 104,
            decoration: BoxDecoration(
              color: AppColors.textPrimary,
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        ),
        const SizedBox(height: 24),
        for (var i = 0; i < 4; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppSkeleton(
              child: Container(
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// This month's total across every category — the dark gradient tile from
/// Home's "This Month" summary card, so the two screens share one visual
/// language for "the big number".
class _TotalSpendCard extends StatelessWidget {
  const _TotalSpendCard({required this.totalCents});

  final int totalCents;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(AppColors.textPrimary, Colors.white, 0.18)!,
            AppColors.textPrimary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Spent This Month',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            formatMad(totalCents),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// One row per category: icon + name + trend on top, amount on the right,
/// and a share-of-total progress bar underneath.
class _CategoryListTile extends StatelessWidget {
  const _CategoryListTile({
    required this.spend,
    required this.shareOfTotal,
    required this.onTap,
  });

  final CategorySpend spend;
  final double shareOfTotal;
  final VoidCallback onTap;

  static const _trendDown = Color(0xFF2FB457);
  static const _trendUp = Color(0xFFE5484D);

  @override
  Widget build(BuildContext context) {
    final delta = spend.deltaPercent;
    final color = CategoryVisuals.colorFor(spend.category.color);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF1F3F5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CategoryAvatar(
                    name: spend.category.name,
                    colorHex: spend.category.color,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          spend.category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: delta == null
                              ? const [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      'New this month',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ]
                              : [
                                  Icon(
                                    delta >= 0
                                        ? Icons.arrow_upward_rounded
                                        : Icons.arrow_downward_rounded,
                                    size: 12,
                                    color: delta >= 0 ? _trendUp : _trendDown,
                                  ),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      '${delta.abs()}% vs last mo.',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: delta >= 0
                                            ? _trendUp
                                            : _trendDown,
                                      ),
                                    ),
                                  ),
                                ],
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
                        formatMad(spend.totalCents),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: shareOfTotal.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: AppColors.background,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${(shareOfTotal * 100).round()}% of spend',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
