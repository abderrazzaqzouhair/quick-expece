import 'package:database/database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../config/router/app_routes.dart';
import '../../shared/formatters.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/pressable.dart';
import 'history_controller.dart';
import 'logic/history_view.dart';
import 'widgets/category_filter_bar.dart';
import 'widgets/expense_detail_sheet.dart';
import 'widgets/expense_tile.dart';
import 'widgets/history_empty_state.dart';
import 'widgets/history_skeleton.dart';
import 'widgets/month_summary_card.dart';
import '../../shared/haptics.dart';

/// Past expenses, month by month: summary card with daily bars (tap a bar
/// to filter to that day), category chips, search, and day-grouped rows
/// with swipe-to-delete + Undo.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  late final TextEditingController _search;
  HistoryView? _lastView;

  @override
  void initState() {
    super.initState();
    // Restores the query kept by the controller across tab switches.
    _search = TextEditingController(
      text: ref.read(historyControllerProvider).filters.query,
    );
  }

  HistoryController get _controller =>
      ref.read(historyControllerProvider.notifier);

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
    final state = ref.watch(historyControllerProvider);
    final filters = state.filters;
    final view = ref.watch(historyViewProvider);
    // Keep the last loaded view so switching months doesn't flash the
    // skeleton — it only shows on the very first load.
    if (view.hasValue) _lastView = view.value;
    final data = view.hasValue ? view.value : _lastView;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'History',
        onProfileTap: () => context.go(AppRoutes.profile),
      ),
      body: switch ((data, view.error)) {
        (null, final Object error) => _LoadError(error: error),
        _ => SkeletonSwitcher(
          isLoading: data == null,
          skeleton: const HistorySkeleton(),
          child: data == null
              ? const SizedBox.shrink()
              // Previous month stays visible (faded) while the next loads.
              : AnimatedOpacity(
                  opacity: view.isLoading ? 0.55 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: _content(data, filters),
                ),
        ),
      },
    );
  }

  Widget _content(HistoryView data, HistoryFilters filters) {
    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverToBoxAdapter(
            child: MonthSummaryCard(
              month: filters.month,
              totalCents: data.monthTotalCents,
              count: data.monthCount,
              dailyTotals: data.dailyTotals,
              selectedDay: filters.day,
              canGoForward: _controller.canGoForward,
              onShiftMonth: _controller.shiftMonth,
              onDayTap: _controller.toggleDay,
            ),
          ),
        ),
        if (!data.isEmptyMonth) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
          SliverToBoxAdapter(
            child: CategoryFilterBar(
              categories: data.categories,
              selectedId: filters.categoryId,
              onTap: _controller.toggleCategory,
            ),
          ),
          if (filters.isFiltered)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _FilterSummary(
                  day: filters.day,
                  count: data.filteredCount,
                  totalCents: data.filteredTotalCents,
                  onClearDay: _controller.clearDay,
                  onClearAll: _clearFilters,
                ),
              ),
            ),
        ],
        if (data.isEmptyMonth)
          SliverToBoxAdapter(
            child: HistoryEmptyState(
              icon: Icons.receipt_long_rounded,
              title:
                  'No expenses in ${DateFormat('MMMM').format(filters.month)}',
              message:
                  'Everything you spend will show up here, '
                  'grouped by day.',
              actionLabel: 'Add expense',
              onAction: () => context.push(AppRoutes.addExpense),
            ),
          )
        else if (data.groups.isEmpty)
          SliverToBoxAdapter(
            child: HistoryEmptyState(
              icon: Icons.search_off_rounded,
              title: 'No matches',
              message: 'Nothing this month matches your filters.',
              actionLabel: 'Clear filters',
              onAction: _clearFilters,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            sliver: SliverList.builder(
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
            ),
          ),
        // Room for the bottom nav + floating create button.
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    debugPrint('Failed to load history: $error');
    return const Center(
      child: Text(
        'Could not load your expenses.',
        style: TextStyle(color: AppColors.error),
      ),
    );
  }
}

/// "3 results · 120.00 MAD" with removable day chip and Clear.
class _FilterSummary extends StatelessWidget {
  const _FilterSummary({
    required this.day,
    required this.count,
    required this.totalCents,
    required this.onClearDay,
    required this.onClearAll,
  });

  final DateTime? day;
  final int count;
  final int totalCents;
  final VoidCallback onClearDay;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (day != null) ...[
          Pressable(
            onTap: onClearDay,
            semanticLabel: 'Remove day filter ${formatDayLabel(day!)}',
            child: Container(
              height: 32,
              padding: const EdgeInsets.only(left: 12, right: 8),
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatDayLabel(day!),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            '$count ${count == 1 ? 'result' : 'results'}  ·  '
            '${formatMad(totalCents)}',
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: onClearAll,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: const Size(44, 36),
          ),
          child: const Text(
            'Clear',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
