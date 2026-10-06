import 'package:database/database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../config/router/app_routes.dart';
import '../../shared/formatters.dart';
import '../../shared/haptics.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/period_selector.dart';
import '../history/widgets/category_filter_bar.dart';
import '../history/widgets/expense_detail_sheet.dart';
import '../history/widgets/expense_tile.dart';
import '../history/widgets/history_empty_state.dart';
import '../statistics/logic/period_stats.dart';
import 'expense_list_controller.dart';
import 'widgets/expense_list_skeleton.dart';

/// Every expense in a chosen period (Week/Month/6M/Year/All), with search,
/// category filtering, sorting, and a "Load more" page through the result —
/// reached from Statistics' "View All Expenses" button.
class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  late final TextEditingController _search;
  ExpenseListView? _lastView;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(
      text: ref.read(expenseListControllerProvider).filters.query,
    );
  }

  ExpenseListController get _controller =>
      ref.read(expenseListControllerProvider.notifier);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _delete(ExpenseDetails details) async {
    Haptics.medium();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final undo = await _controller.delete(details.expense.id);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          appToast(
            '${details.subcategory.name} · '
            '${formatMad(details.expense.amountCents)} deleted',
            actionLabel: 'Undo',
            onAction: () {
              Haptics.light();
              undo();
            },
          ),
        );
    } catch (e, stack) {
      debugPrint('Failed to delete expense: $e\n$stack');
      messenger.showSnackBar(
        appToast('Could not delete the expense.', kind: ToastKind.error),
      );
    }
  }

  Future<void> _openDetails(ExpenseDetails details) async {
    final delete = await showExpenseDetailSheet(context, details);
    if (delete == true) await _delete(details);
  }

  void _clearFilters() {
    _search.clear();
    _controller.clearAll();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseListControllerProvider);
    final filters = state.filters;
    final view = ref.watch(expenseListViewProvider);
    // Keep the last loaded view so switching period/sort/filters doesn't
    // flash the skeleton — it only shows on the very first load.
    if (view.hasValue) _lastView = view.value;
    final data = view.hasValue ? view.value : _lastView;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${filters.period.label} Expenses'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: switch ((data, view.error)) {
        (null, final Object error) => _LoadError(error: error),
        _ => SkeletonSwitcher(
          isLoading: data == null,
          skeleton: const ExpenseListSkeleton(),
          child: data == null
              ? const SizedBox.shrink()
              : AnimatedOpacity(
                  opacity: view.isLoading ? 0.55 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: _content(data, filters),
                ),
        ),
      },
    );
  }

  Widget _content(ExpenseListView data, ExpenseListFilters filters) {
    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverToBoxAdapter(
            child: PeriodSelector(
              selected: filters.period,
              onChanged: (p) {
                Haptics.selection();
                _controller.setPeriod(p);
              },
            ),
          ),
        ),
        if (!data.isEmptyPeriod) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _SummaryRow(
                count: data.filteredCount,
                totalCents: data.filteredTotalCents,
                sort: filters.sort,
                onSortChanged: _controller.setSort,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverToBoxAdapter(
              child: CupertinoSearchTextField(
                controller: _search,
                onChanged: _controller.setQuery,
                placeholder: 'Search notes or categories',
                backgroundColor: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(
            child: CategoryFilterBar(
              categories: data.categories,
              selectedId: filters.categoryId,
              onTap: _controller.toggleCategory,
            ),
          ),
        ],
        if (data.isEmptyPeriod)
          SliverToBoxAdapter(
            child: HistoryEmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'No expenses ${_periodPhrase(filters.period)}',
              message:
                  'Everything you spend will show up here once you add '
                  'expenses.',
              actionLabel: 'Add expense',
              onAction: () => context.push(AppRoutes.addExpense),
            ),
          )
        else if (data.isEmptyFiltered)
          SliverToBoxAdapter(
            child: HistoryEmptyState(
              icon: Icons.search_off_rounded,
              title: 'No matches',
              message: 'Nothing in this period matches your filters.',
              actionLabel: 'Clear filters',
              onAction: _clearFilters,
            ),
          )
        else ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            sliver: data.groups.isNotEmpty
                ? SliverList.builder(
                    itemCount: data.groups.length,
                    itemBuilder: (context, i) {
                      final group = data.groups[i];
                      return DaySection(
                        label: formatDayLabel(group.day),
                        totalCents: group.totalCents,
                        children: [
                          for (final details in group.items)
                            ExpenseTile(
                              key: ValueKey(details.expense.id),
                              details: details,
                              onTap: () => _openDetails(details),
                              onDelete: () => _delete(details),
                            ),
                        ],
                      );
                    },
                  )
                : SliverList.builder(
                    itemCount: data.flatItems.length,
                    itemBuilder: (context, i) {
                      final details = data.flatItems[i];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ColoredBox(
                            color: AppColors.surface,
                            child: ExpenseTile(
                              key: ValueKey(details.expense.id),
                              details: details,
                              onTap: () => _openDetails(details),
                              onDelete: () => _delete(details),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SliverToBoxAdapter(
            child: _LoadMoreFooter(
              shown: data.visibleCount,
              total: data.filteredCount,
              hasMore: data.hasMore,
              onLoadMore: _controller.loadMore,
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

String _periodPhrase(StatsPeriod period) => switch (period) {
  StatsPeriod.today => 'today',
  StatsPeriod.week => 'this week',
  StatsPeriod.month => 'this month',
  StatsPeriod.sixMonths => 'in the last 6 months',
  StatsPeriod.year => 'in the last 12 months',
  StatsPeriod.all => 'yet',
};

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    debugPrint('Failed to load expenses: $error');
    return const Center(
      child: Text(
        'Could not load your expenses.',
        style: TextStyle(color: AppColors.error),
      ),
    );
  }
}

/// "12 results · 420.00 MAD" with a sort menu on the trailing side.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.count,
    required this.totalCents,
    required this.sort,
    required this.onSortChanged,
  });

  final int count;
  final int totalCents;
  final ExpenseSort sort;
  final ValueChanged<ExpenseSort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$count ${count == 1 ? 'expense' : 'expenses'}  ·  '
            '${formatMad(totalCents)}',
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        PopupMenuButton<ExpenseSort>(
          initialValue: sort,
          onSelected: onSortChanged,
          icon: const Icon(
            Icons.swap_vert_rounded,
            size: 22,
            color: AppColors.textSecondary,
          ),
          itemBuilder: (context) => [
            for (final option in ExpenseSort.values)
              PopupMenuItem(
                value: option,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(option.label),
                    if (option == sort)
                      const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// "Load 30 more" button, or nothing once everything is shown.
class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({
    required this.shown,
    required this.total,
    required this.hasMore,
    required this.onLoadMore,
  });

  final int shown;
  final int total;
  final bool hasMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (!hasMore) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: [
          OutlinedButton(
            onPressed: () {
              Haptics.light();
              onLoadMore();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              minimumSize: const Size(double.infinity, 46),
              shape: const StadiumBorder(),
            ),
            child: const Text(
              'Load more',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Showing $shown of $total',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
