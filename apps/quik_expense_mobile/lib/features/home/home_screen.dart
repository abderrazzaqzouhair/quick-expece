import 'dart:math' as math;

import 'package:database/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../config/providers/database_providers.dart';
import '../../config/router/app_routes.dart';
import '../../shared/category_visuals.dart';
import '../../shared/formatters.dart';
import '../../shared/spending.dart';
import '../../shared/widgets/app_toast.dart';
import '../history/history_controller.dart';
import '../history/widgets/expense_detail_sheet.dart';
import '../profile/data/profile_store.dart';
import 'logic/home_extras.dart';
import 'logic/home_view.dart';
import 'widgets/home_skeleton.dart';
import 'widgets/insights_list.dart';
import 'widgets/quick_add_row.dart';
import 'widgets/week_chart.dart';
import '../../shared/haptics.dart';

/// Dashboard, live from the local database: greeting, a week/month
/// calendar (dots mark days with spending; selecting a day drives
/// everything below), day/month totals with context, Quick Add shortcuts,
/// top categories with a trend vs last month, the selected week's daily
/// bars, auto-generated insights, and the latest expenses.
///
/// There's no income/budget model, so nothing here fabricates a salary or
/// a budget target — every figure is a real sum of recorded expenses.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime _selectedDate = dateOnly(DateTime.now());

  /// Expanded (default): the full month grid. Collapsed: one week around
  /// the selected day, for more room below.
  bool _expanded = true;

  /// Month shown when expanded (chevrons page it).
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);

  /// Last loaded view — kept while another month loads so the dashboard
  /// doesn't flash back to the skeleton.
  HomeView? _lastView;
  List<Insight> _lastInsights = const [];

  void _toggleCalendar() {
    Haptics.selection();
    setState(() {
      _expanded = !_expanded;
      _visibleMonth = DateTime(_selectedDate.year, _selectedDate.month);
    });
  }

  /// Chevrons page by week when collapsed (moving the selection with it),
  /// by month when expanded.
  void _page(int direction) {
    Haptics.selection();
    setState(() {
      if (_expanded) {
        _visibleMonth = DateTime(
          _visibleMonth.year,
          _visibleMonth.month + direction,
        );
      } else {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day + 7 * direction,
        );
      }
    });
  }

  void _openCategory(CategorySpend spend) {
    Haptics.selection();
    ref
        .read(historyControllerProvider.notifier)
        .showCategory(_selectedDate, spend.category.id);
    context.go(AppRoutes.history);
  }

  void _quickAdd(QuickAddItem item) {
    Haptics.selection();
    context.push(
      AppRoutes.addExpense,
      extra: (category: item.category, subcategory: item.subcategory),
    );
  }

  Future<void> _openExpense(ExpenseDetails details) async {
    final delete = await showExpenseDetailSheet(context, details);
    if (delete != true || !mounted) return;
    Haptics.medium();
    final messenger = ScaffoldMessenger.of(context);
    final dao = ref.read(appDatabaseProvider).expensesDao;
    await dao.softDelete(details.expense.id);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        appToast(
          '${details.subcategory.name} · '
          '${formatMad(details.expense.amountCents)} deleted',
          actionLabel: 'Undo',
          onAction: () => dao.restore(details.expense.id),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final month = _expanded
        ? _visibleMonth
        : DateTime(_selectedDate.year, _selectedDate.month);
    final days = _expanded ? calendarGrid(month) : weekOf(_selectedDate);
    final profile = ref.watch(profileProvider);

    final data = ref.watch(
      expensesInRangeProvider(homeDataRange(_selectedDate)),
    );
    if (data.hasValue) {
      _lastView = buildHomeView(data.value!, _selectedDate);
      _lastInsights = buildInsights(data.value!, _selectedDate);
    }
    final view = _lastView;

    final gridExpenses = ref
        .watch(
          expensesInRangeProvider((
            from: days.first,
            to: DateTime(days.last.year, days.last.month, days.last.day + 1),
          )),
        )
        .value;
    final recent = ref.watch(recentExpensesProvider);
    final isFirstRun = recent.hasValue && recent.value!.isEmpty;

    final week = weekOf(_selectedDate);
    final weekExpenses = ref
        .watch(
          expensesInRangeProvider((
            from: week.first,
            to: DateTime(week.last.year, week.last.month, week.last.day + 1),
          )),
        )
        .value;
    final quickAdd = quickAddSuggestions(
      ref.watch(expensesInRangeProvider(quickAddRange(DateTime.now()))).value ??
          const [],
    );
    final isThisWeek = week.contains(dateOnly(DateTime.now()));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'Home',
        onProfileTap: () => context.go(AppRoutes.profile),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 20, 14, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Greeting(name: profile.hasName ? profile.name : null),
            const SizedBox(height: 16),
            _WeekCalendarStrip(
              month: month,
              days: days,
              expanded: _expanded,
              selectedDate: _selectedDate,
              daysWithSpend: gridExpenses == null
                  ? const {}
                  : daysWithSpend(gridExpenses),
              onToggle: _toggleCalendar,
              onPreviousPeriod: () => _page(-1),
              onNextPeriod: () => _page(1),
              onDaySelected: (date) {
                Haptics.selection();
                setState(() => _selectedDate = dateOnly(date));
              },
            ),
            const SizedBox(height: 20),
            SkeletonSwitcher(
              isLoading: view == null || !recent.hasValue,
              skeleton: const HomeSkeleton(),
              child: view == null
                  ? const SizedBox.shrink()
                  : AnimatedOpacity(
                      opacity: data.isLoading ? 0.6 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: isFirstRun
                          ? _WelcomeCard(
                              onAdd: () => context.push(AppRoutes.addExpense),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SummaryCards(
                                  selectedDate: _selectedDate,
                                  view: view,
                                ),
                                if (quickAdd.isNotEmpty) ...[
                                  const SizedBox(height: 22),
                                  QuickAddRow(
                                    items: quickAdd,
                                    onTap: _quickAdd,
                                  ),
                                ],
                                const SizedBox(height: 24),
                                _SectionCard(
                                  // The card list scrolls edge to edge; the
                                  // section insets its own header instead.
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                  child: _TopCategoriesCard(
                                    categories: view.categories,
                                    total: view.monthTotalCents ?? 0,
                                    onSeeAll: () =>
                                        context.push(AppRoutes.categories),
                                    onCategoryTap: _openCategory,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _SectionCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _PremiumSectionHeader(
                                        title: isThisWeek
                                            ? 'This Week'
                                            : 'Week of ${DateFormat.MMMd('en_US').format(week.first)}',
                                        onSeeAll: () =>
                                            context.go(AppRoutes.statistics),
                                      ),
                                      const SizedBox(height: 12),
                                      WeekChart(
                                        days: week,
                                        totals: weekTotals(
                                          weekExpenses ?? const [],
                                          week.first,
                                        ),
                                        selectedDay: _selectedDate,
                                        onDayTap: (day) {
                                          Haptics.selection();
                                          setState(() => _selectedDate = day);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                if (_lastInsights.isNotEmpty) ...[
                                  const SizedBox(height: 24),
                                  _SectionCard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Insights',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        InsightsList(insights: _lastInsights),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                _SectionCard(
                                  child: _RecentExpensesSection(
                                    expenses: recent.value ?? const [],
                                    onSeeAll: () =>
                                        context.go(AppRoutes.history),
                                    onAdd: () =>
                                        context.push(AppRoutes.addExpense),
                                    onTap: _openExpense,
                                  ),
                                ),
                              ],
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _colorOf(CategoryRow category) =>
    CategoryVisuals.colorFor(category.color);

/// "Today" / "Yesterday" for the two most recent days, otherwise a plain
/// formatted date — same convention used across the recent-expenses list.
String _relativeDateLabel(DateTime date) {
  final label = formatDayLabel(date);
  return label == 'Today' || label == 'Yesterday'
      ? label
      : DateFormat.MMMd('en_US').format(date);
}

/// Calendar strip — every day of [month] as a real computed Monday-Sunday
/// grid (4-6 rows depending on the month). Padding days that spill into the
/// previous/next month are dimmed. Days with spending get a small dot;
/// selecting a day drives the summary cards.
class _WeekCalendarStrip extends StatelessWidget {
  const _WeekCalendarStrip({
    required this.month,
    required this.days,
    required this.expanded,
    required this.selectedDate,
    required this.daysWithSpend,
    required this.onToggle,
    required this.onPreviousPeriod,
    required this.onNextPeriod,
    required this.onDaySelected,
  });

  final DateTime month;
  final List<DateTime> days;
  final bool expanded;
  final DateTime selectedDate;
  final Set<DateTime> daysWithSpend;
  final VoidCallback onToggle;
  final VoidCallback onPreviousPeriod;
  final VoidCallback onNextPeriod;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final headerMonth = DateFormat.yMMMM('en_US').format(month);
    final rows = <List<DateTime>>[
      for (var i = 0; i < days.length; i += 7) days.sublist(i, i + 7),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: onPreviousPeriod,
              tooltip: expanded ? 'Previous month' : 'Previous week',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.chevron_left, color: AppColors.primary),
            ),
            // Tap the month to switch between week strip and full month.
            // Flexible: long month names shrink instead of pushing the
            // arrows off-screen with large text.
            Flexible(
              child: Semantics(
                button: true,
                label: '$headerMonth. ${expanded ? 'Show week' : 'Show month'}',
                excludeSemantics: true,
                child: InkWell(
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            headerMonth,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        AnimatedRotation(
                          turns: expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 220),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: onNextPeriod,
              tooltip: expanded ? 'Next month' : 'Next week',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.chevron_right, color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final day in rows.first)
              SizedBox(
                width: 36,
                child: Text(
                  DateFormat('EEEEE', 'en_US').format(day),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              for (final row in rows)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final day in row)
                      _DayCell(
                        date: day,
                        isSelected: day == selectedDate,
                        // A collapsed week can span two months — only dim
                        // padding days in the full-month grid.
                        isInVisibleMonth: !expanded || day.month == month.month,
                        isFuture: day.isAfter(dateOnly(DateTime.now())),
                        hasSpend: daysWithSpend.contains(day),
                        onTap: () => onDaySelected(day),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.isSelected,
    required this.isInVisibleMonth,
    required this.isFuture,
    required this.hasSpend,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final bool isInVisibleMonth;

  /// Future days are lighter — nothing can have been spent yet.
  final bool isFuture;
  final bool hasSpend;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Padding days from the adjacent month are dimmed rather than hidden —
    // keeps every row a full week while making clear they're not "this
    // month", same as a standard calendar grid.
    final mutedOpacity = isInVisibleMonth ? 1.0 : 0.35;

    return Semantics(
      button: true,
      selected: isSelected,
      label:
          '${DateFormat.yMMMMd('en_US').format(date)}'
          '${hasSpend ? ', has expenses' : ''}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Opacity(
            opacity: mutedOpacity,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  width: 36,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isFuture ? FontWeight.w500 : FontWeight.w700,
                      color: isSelected
                          ? AppColors.onPrimary
                          : isFuture
                          ? AppColors.textSecondary.withValues(alpha: 0.6)
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                // Activity dot: days with at least one expense.
                AnimatedOpacity(
                  opacity: hasSpend ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Selected-day / selected-month cards. Orange for the day figure, a
/// derived charcoal tone for the month figure, each with a context line
/// (expense count, trend vs last month). Both track [selectedDate] —
/// picking a day from an adjacent month switches the month card too.
class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.selectedDate, required this.view});

  final DateTime selectedDate;
  final HomeView view;

  bool _isToday(DateTime date) => date == dateOnly(DateTime.now());

  bool _isCurrentMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  static String _count(int n) => '$n ${n == 1 ? 'expense' : 'expenses'}';

  @override
  Widget build(BuildContext context) {
    final dayLabel = _isToday(selectedDate)
        ? 'Today'
        : DateFormat.MMMd('en_US').format(selectedDate);
    final monthLabel = _isCurrentMonth(selectedDate)
        ? 'This Month'
        : DateFormat.yMMM('en_US').format(selectedDate);
    final delta = view.monthDeltaPercent;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _SummaryCard(
              label: dayLabel,
              amountCents: view.dayTotalCents,
              detail: view.dayCount == 0
                  ? 'Nothing spent'
                  : _count(view.dayCount),
              gradientColors: [AppColors.primaryLight, AppColors.primary],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              label: monthLabel,
              amountCents: view.monthTotalCents,
              detail: delta == null
                  ? (view.monthCount == 0
                        ? 'Nothing spent'
                        : _count(view.monthCount))
                  : '${delta >= 0 ? '↑' : '↓'} ${delta.abs()}% vs last month',
              gradientColors: [
                Color.lerp(AppColors.textPrimary, Colors.white, 0.18)!,
                AppColors.textPrimary,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.amountCents,
    required this.detail,
    required this.gradientColors,
  });

  final String label;
  // `null` renders a "no expenses" placeholder instead of an amount.
  final int? amountCents;
  final String detail;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    final amount = amountCents;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                amount == null ? 'No expenses' : formatMad(amount),
                key: ValueKey(amount),
                style: TextStyle(
                  fontSize: amount == null ? 15 : 19,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(
                    alpha: amount == null ? 0.75 : 1,
                  ),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Top Categories" — a horizontally scrolling row of the selected month's
/// category cards, biggest first. Tapping a card opens History filtered to
/// that category.
class _TopCategoriesCard extends StatelessWidget {
  const _TopCategoriesCard({
    required this.categories,
    required this.total,
    required this.onSeeAll,
    required this.onCategoryTap,
  });

  final List<CategorySpend> categories;
  final int total;
  final VoidCallback onSeeAll;
  final ValueChanged<CategorySpend> onCategoryTap;

  /// Matches the other sections' 20px card padding.
  static const _inset = 20.0;
  static const _gap = 12.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _inset),
          child: _PremiumSectionHeader(
            title: 'Top Categories',
            onSeeAll: onSeeAll,
          ),
        ),
        const SizedBox(height: 24),
        if (categories.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: _inset),
            child: Text(
              'No expenses this month — your top categories will show up here.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          )
        else
          // A little taller than the card itself and unclipped, so each
          // card's own drop shadow has room to render. Cards are sized so
          // two fit fully between equal margins; more scroll in.
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = math.max(
                148.0,
                (constraints.maxWidth - _inset * 2 - _gap) / 2,
              );
              return SizedBox(
                height: _categoryCardHeight(context) + 12,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  clipBehavior: Clip.none,
                  // First card lines up with the title; the last one ends with
                  // the same margin instead of being sliced by the card edge.
                  padding: const EdgeInsets.symmetric(horizontal: _inset),
                  itemCount: categories.length,
                  separatorBuilder: (context, _) => const SizedBox(width: _gap),
                  itemBuilder: (context, i) => _PremiumCategoryCard(
                    spend: categories[i],
                    width: cardWidth,
                    isLargest: i == 0,
                    shareOfTotal: total == 0
                        ? 0
                        : categories[i].totalCents / total,
                    onTap: () => onCategoryTap(categories[i]),
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// Title (20px SemiBold near-black) and a "See all" action sharing a row.
class _PremiumSectionHeader extends StatelessWidget {
  const _PremiumSectionHeader({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Yields to "See all" with large system text instead of overflowing.
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _ViewAllButton(onTap: onSeeAll),
      ],
    );
  }
}

class _ViewAllButton extends StatefulWidget {
  const _ViewAllButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_ViewAllButton> createState() => _ViewAllButtonState();
}

class _ViewAllButtonState extends State<_ViewAllButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'See all',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: Padding(
          // Comfortable tap target around the small label.
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: AnimatedScale(
            scale: _pressed ? 0.94 : 1,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.primary.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single category card with a physics-based spring press animation.
class _PremiumCategoryCard extends StatefulWidget {
  const _PremiumCategoryCard({
    required this.spend,
    required this.width,
    required this.isLargest,
    required this.shareOfTotal,
    required this.onTap,
  });

  final CategorySpend spend;
  final double width;
  final bool isLargest;
  final double shareOfTotal;
  final VoidCallback onTap;

  @override
  State<_PremiumCategoryCard> createState() => _PremiumCategoryCardState();
}

class _PremiumCategoryCardState extends State<_PremiumCategoryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // controller.value doubles as "press amount" (0 = rest, 1 = pressed).
  void _animateTo(double target) {
    final simulation = SpringSimulation(
      const SpringDescription(mass: 1, stiffness: 300, damping: 22),
      _controller.value,
      target,
      0,
    );
    _controller.animateWith(simulation);
  }

  @override
  Widget build(BuildContext context) {
    final spend = widget.spend;
    return Semantics(
      button: true,
      label:
          '${spend.category.name}, ${formatMad(spend.totalCents)}. '
          'Show in history',
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => _animateTo(1),
        onTapUp: (_) => _animateTo(0),
        onTapCancel: () => _animateTo(0),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final pressT = _controller.value.clamp(0.0, 1.0);
            return Transform.scale(
              scale: 1 - (0.02 * pressT),
              child: _CategoryCardSurface(
                spend: spend,
                width: widget.width,
                isLargest: widget.isLargest,
                shareOfTotal: widget.shareOfTotal,
                pressT: pressT,
              ),
            );
          },
        ),
      ),
    );
  }
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// 140 at normal text size, growing with the system text scale so the
/// name, amount and pill never clip.
double _categoryCardHeight(BuildContext context) =>
    140 + 40 * (MediaQuery.textScalerOf(context).scale(1) - 1).clamp(0, 2);

/// A plain white card: category icon + name on top, the big amount, and a
/// colored pill underneath (share of spend for the leader, trend vs last
/// month for the rest).
class _CategoryCardSurface extends StatelessWidget {
  const _CategoryCardSurface({
    required this.spend,
    required this.width,
    required this.isLargest,
    required this.shareOfTotal,
    required this.pressT,
  });

  final CategorySpend spend;
  final double width;
  final bool isLargest;
  final double shareOfTotal;
  final double pressT;

  // iOS system green/red — spend down vs last month is "good" (green), up is
  // "watch out" (red).
  static const _trendDown = Color(0xFF2FB457);
  static const _trendUp = Color(0xFFE5484D);

  @override
  Widget build(BuildContext context) {
    final category = spend.category;
    return Container(
      width: width,
      height: _categoryCardHeight(context),
      padding: const EdgeInsets.all(14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F3F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _lerp(0.03, 0.06, pressT)),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Names wrap to two lines on the half-width card
          // ("Housing & Living") rather than clipping.
          SizedBox(
            height: 36,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CategoryAvatar(
                  name: category.name,
                  colorHex: category.color,
                  size: 26,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: formatAmount(spend.totalCents),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const TextSpan(
                    text: '  MAD',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
            ),
          ),
          const Spacer(),
          _buildTrendPill(),
        ],
      ),
    );
  }

  Widget _buildTrendPill() {
    final IconData icon;
    final Color color;
    final String label;
    final delta = spend.deltaPercent;

    if (isLargest) {
      icon = Icons.star_rounded;
      color = _colorOf(spend.category);
      label = '${(shareOfTotal * 100).round()}% share';
    } else if (delta == null) {
      // Nothing spent on it last month — a % change would be meaningless.
      icon = Icons.auto_awesome_rounded;
      color = _colorOf(spend.category);
      label = 'New';
    } else {
      final isUp = delta >= 0;
      icon = isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
      color = isUp ? _trendUp : _trendDown;
      // Short enough for the half-width card; "vs last month" is implied.
      label = '${delta.abs()}% ${isUp ? 'more' : 'less'}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable white "card" wrapper — flat white background + soft shadow.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// The latest few expenses (all time). Tap one for details; "See all" goes
/// to History.
class _RecentExpensesSection extends StatelessWidget {
  const _RecentExpensesSection({
    required this.expenses,
    required this.onSeeAll,
    required this.onAdd,
    required this.onTap,
  });

  final List<ExpenseDetails> expenses;
  final VoidCallback onSeeAll;
  final VoidCallback onAdd;
  final ValueChanged<ExpenseDetails> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PremiumSectionHeader(title: 'Recent Expenses', onSeeAll: onSeeAll),
        const SizedBox(height: 4),
        if (expenses.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'No expenses yet.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onAdd,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    'Add expense',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          )
        else
          for (final details in expenses)
            _TransactionRow(details: details, onTap: () => onTap(details)),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.details, required this.onTap});

  final ExpenseDetails details;
  final VoidCallback onTap;

  /// "14:05" today, "Yesterday", or "Oct 3" — short, so it never clips.
  String _timeLabel(DateTime date) {
    final day = _relativeDateLabel(date);
    return day == 'Today' ? DateFormat.Hm().format(date) : day;
  }

  @override
  Widget build(BuildContext context) {
    final expense = details.expense;
    return Semantics(
      button: true,
      label:
          '${details.category.name}, ${details.subcategory.name}, '
          '${formatMad(expense.amountCents)}, ${_timeLabel(expense.date)}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CategoryAvatar(
                name: details.category.name,
                colorHex: details.category.color,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Same hierarchy as History: what, then why/where.
                    Text(
                      details.subcategory.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      expense.note ?? details.category.name,
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
              const SizedBox(width: 10),
              Flexible(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatMad(expense.amountCents),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _timeLabel(expense.date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Good morning, Sara" + today's date.
class _Greeting extends StatelessWidget {
  const _Greeting({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final first = name?.trim().split(RegExp(r'\s+')).first;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, d MMMM', 'en_US').format(now),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            first == null ? greetingFor(now) : '${greetingFor(now)}, $first',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// First run (no expenses at all): one inviting card instead of a stack of
/// empty sections.
class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.onAdd});

  final VoidCallback onAdd;

  static const _tips = [
    (Icons.dialpad_rounded, 'Type the amount on the keypad'),
    (Icons.grid_view_rounded, 'Pick a category'),
    (Icons.insights_rounded, 'Watch your totals and trends here'),
  ];

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        children: [
          const SizedBox(height: 4),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Start tracking your spending',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add your first expense — it takes about five seconds.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          for (final (icon, text) in _tips)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          AppPrimaryButton(
            label: 'Add your first expense',
            trailingIcon: Icons.arrow_forward_rounded,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}
