import 'dart:math' as math;

import 'package:database/database.dart';
import 'package:fl_chart/fl_chart.dart';
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
import 'logic/home_view.dart';
import 'widgets/home_skeleton.dart';
import '../../shared/haptics.dart';

/// Dashboard, live from the local database: a month calendar (dots mark
/// days with spending; selecting a day drives the summary cards), the
/// selected month's top categories with a trend vs last month, an exploded
/// pie of where the money went, and the latest expenses.
///
/// There's no income/budget model, so nothing here fabricates a salary or
/// a budget target — every figure is a real sum of recorded expenses.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // In months, relative to the current one.
  int _monthOffset = 0;
  DateTime _selectedDate = dateOnly(DateTime.now());

  /// Last loaded view — kept while another month loads so the dashboard
  /// doesn't flash back to the skeleton.
  HomeView? _lastView;

  DateTime get _visibleMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month + _monthOffset);
  }

  void _openCategory(CategorySpend spend) {
    Haptics.selection();
    ref
        .read(historyControllerProvider.notifier)
        .showCategory(_selectedDate, spend.category.id);
    context.go(AppRoutes.history);
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
    final month = _visibleMonth;
    final days = calendarGrid(month);

    final data = ref.watch(
      expensesInRangeProvider(homeDataRange(_selectedDate)),
    );
    if (data.hasValue) _lastView = buildHomeView(data.value!, _selectedDate);
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
            _WeekCalendarStrip(
              month: month,
              days: days,
              selectedDate: _selectedDate,
              daysWithSpend: gridExpenses == null
                  ? const {}
                  : daysWithSpend(gridExpenses),
              onPreviousPeriod: () => setState(() => _monthOffset--),
              onNextPeriod: () => setState(() => _monthOffset++),
              onDaySelected: (date) =>
                  setState(() => _selectedDate = dateOnly(date)),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SummaryCards(
                            selectedDate: _selectedDate,
                            selectedDaySpend: view.dayTotalCents,
                            selectedMonthSpend: view.monthTotalCents,
                          ),
                          const SizedBox(height: 20),
                          _PremiumCard(
                            child: _TopCategoriesCard(
                              categories: view.categories,
                              total: view.monthTotalCents ?? 0,
                              onSeeAll: () => context.go(AppRoutes.statistics),
                              onCategoryTap: _openCategory,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _SectionCard(
                            child: _AnalyticsSection(
                              categories: view.categories,
                              total: view.monthTotalCents ?? 0,
                              onSeeAll: () => context.go(AppRoutes.statistics),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _SectionCard(
                            child: _RecentExpensesSection(
                              expenses: recent.value ?? const [],
                              onSeeAll: () => context.go(AppRoutes.history),
                              onAdd: () => context.push(AppRoutes.addExpense),
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
    required this.selectedDate,
    required this.daysWithSpend,
    required this.onPreviousPeriod,
    required this.onNextPeriod,
    required this.onDaySelected,
  });

  final DateTime month;
  final List<DateTime> days;
  final DateTime selectedDate;
  final Set<DateTime> daysWithSpend;
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
              tooltip: 'Previous month',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.chevron_left, color: AppColors.primary),
            ),
            Text(
              headerMonth,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            IconButton(
              onPressed: onNextPeriod,
              tooltip: 'Next month',
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
        for (final row in rows)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final day in row)
                _DayCell(
                  date: day,
                  isSelected: day == selectedDate,
                  isInVisibleMonth: day.month == month.month,
                  hasSpend: daysWithSpend.contains(day),
                  onTap: () => onDaySelected(day),
                ),
            ],
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
    required this.hasSpend,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final bool isInVisibleMonth;
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
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.onPrimary
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
/// derived charcoal tone for the month figure. Both labels and both amounts
/// track [selectedDate] — picking a day from an adjacent month (shown
/// dimmed in the calendar grid) switches the right card to that month too.
class _SummaryCards extends StatelessWidget {
  const _SummaryCards({
    required this.selectedDate,
    required this.selectedDaySpend,
    required this.selectedMonthSpend,
  });

  final DateTime selectedDate;
  final int? selectedDaySpend;
  final int? selectedMonthSpend;

  bool _isToday(DateTime date) => date == dateOnly(DateTime.now());

  bool _isCurrentMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    final dayLabel = _isToday(selectedDate)
        ? 'Today'
        : DateFormat.MMMd('en_US').format(selectedDate);
    final monthLabel = _isCurrentMonth(selectedDate)
        ? 'This Month'
        : DateFormat.yMMM('en_US').format(selectedDate);

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: dayLabel,
            amountCents: selectedDaySpend,
            gradientColors: [AppColors.primaryLight, AppColors.primary],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: monthLabel,
            amountCents: selectedMonthSpend,
            gradientColors: [
              Color.lerp(AppColors.textPrimary, Colors.white, 0.18)!,
              AppColors.textPrimary,
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.amountCents,
    required this.gradientColors,
  });

  final String label;
  // `null` renders a "no expenses" placeholder instead of an amount.
  final int? amountCents;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    final amount = amountCents;
    return Container(
      padding: const EdgeInsets.all(18),
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
          const SizedBox(height: 14),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PremiumSectionHeader(title: 'Top Categories', onSeeAll: onSeeAll),
        const SizedBox(height: 24),
        if (categories.isEmpty)
          const Text(
            'No expenses this month — your top categories will show up here.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          )
        else
          // A little taller than the card itself and unclipped, so each
          // card's own drop shadow has room to render.
          SizedBox(
            height: _categoryCardHeight(context) + 12,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              clipBehavior: Clip.none,
              itemCount: categories.length,
              separatorBuilder: (context, _) => const SizedBox(width: 14),
              itemBuilder: (context, i) => _PremiumCategoryCard(
                spend: categories[i],
                isLargest: i == 0,
                shareOfTotal: total == 0 ? 0 : categories[i].totalCents / total,
                onTap: () => onCategoryTap(categories[i]),
              ),
            ),
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
    required this.isLargest,
    required this.shareOfTotal,
    required this.onTap,
  });

  final CategorySpend spend;
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

/// 128 at normal text size, growing with the system text scale so the
/// name, amount and pill never clip.
double _categoryCardHeight(BuildContext context) =>
    128 + 30 * (MediaQuery.textScalerOf(context).scale(1) - 1).clamp(0, 2);

/// A plain white card: category icon + name on top, the big amount, and a
/// colored pill underneath (share of spend for the leader, trend vs last
/// month for the rest).
class _CategoryCardSurface extends StatelessWidget {
  const _CategoryCardSurface({
    required this.spend,
    required this.isLargest,
    required this.shareOfTotal,
    required this.pressT,
  });

  final CategorySpend spend;
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
      width: 176,
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
          Row(
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: NumberFormat(
                    '#,##0',
                    'en_US',
                  ).format(spend.totalCents / 100),
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
            overflow: TextOverflow.ellipsis,
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
      label = '${(shareOfTotal * 100).round()}% of spend';
    } else if (delta == null) {
      // Nothing spent on it last month — a % change would be meaningless.
      icon = Icons.auto_awesome_rounded;
      color = _colorOf(spend.category);
      label = 'New this month';
    } else {
      final isUp = delta >= 0;
      icon = isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
      color = isUp ? _trendUp : _trendDown;
      label = '${delta.abs()}% vs last mo.';
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

/// A floating white card for premium sections: 28px radius, 24px padding, a
/// large soft low-opacity shadow.
class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Reusable white "card" wrapper — flat white background + soft shadow.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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

  /// "9:20 AM" for today's entries; "Yesterday, 8:30 PM" otherwise.
  String _timeLabel(DateTime date) {
    final time = DateFormat.jm('en_US').format(date);
    final day = _relativeDateLabel(date);
    return day == 'Today' ? time : '$day, $time';
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
                    Text(
                      details.category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      expense.note ?? details.subcategory.name,
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
                        '-${formatMad(expense.amountCents)}',
                        style: const TextStyle(
                          fontSize: 13.5,
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

/// Legend (top 4 categories) beside an *exploded* pie — each wedge pulled
/// apart from the others.
///
/// fl_chart has no "explode" option, so this renders one full [PieChart]
/// per category with every other section transparent, then translates each
/// outward along its own slice's bisecting angle. The angle math only uses
/// the amounts + `startDegreeOffset: -90` (fl_chart's clockwise-from-12
/// convention), not internal fl_chart geometry.
class _AnalyticsSection extends StatelessWidget {
  const _AnalyticsSection({
    required this.categories,
    required this.total,
    required this.onSeeAll,
  });

  final List<CategorySpend> categories;
  final int total;
  final VoidCallback onSeeAll;

  static const _chartSize = 150.0;
  static const _explodeDistance = 9.0;

  @override
  Widget build(BuildContext context) {
    final top4 = categories.take(4).toList();
    final sum = top4.fold(0, (s, c) => s + c.totalCents);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PremiumSectionHeader(title: 'Analytics', onSeeAll: onSeeAll),
        const SizedBox(height: 20),
        if (top4.isEmpty)
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Add a few expenses to see where your money goes.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < top4.length; i++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: i == top4.length - 1 ? 0 : 16,
                        ),
                        child: _CategoryLegendItem(spend: top4[i]),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: _chartSize,
                height: _chartSize,
                child: _buildExplodedPie(top4, sum),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildExplodedPie(List<CategorySpend> top4, int sum) {
    // A single slice is a full circle — nothing to explode.
    final explode = top4.length > 1 ? _explodeDistance : 0.0;
    var cumulativeDegrees = 0.0;
    final slices = <Widget>[];

    for (var i = 0; i < top4.length; i++) {
      final sweep = sum == 0
          ? 360.0 / top4.length
          : top4[i].totalCents / sum * 360;
      final midAngleRad = (-90 + cumulativeDegrees + sweep / 2) * math.pi / 180;
      cumulativeDegrees += sweep;

      slices.add(
        Transform.translate(
          offset: Offset(
            math.cos(midAngleRad) * explode,
            math.sin(midAngleRad) * explode,
          ),
          child: PieChart(
            PieChartData(
              sections: [
                for (var j = 0; j < top4.length; j++)
                  PieChartSectionData(
                    value: top4[j].totalCents.toDouble(),
                    color: i == j
                        ? _colorOf(top4[j].category)
                        : Colors.transparent,
                    radius: 72,
                    showTitle: i == j,
                    title: total == 0
                        ? '0%'
                        : '${(top4[j].totalCents / total * 100).round()}%',
                    titleStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    titlePositionPercentageOffset: top4.length == 1 ? 0 : 0.62,
                    borderSide: i == j
                        ? const BorderSide(color: Colors.white, width: 2)
                        : BorderSide.none,
                  ),
              ],
              centerSpaceRadius: 0,
              sectionsSpace: 0,
              startDegreeOffset: -90,
            ),
          ),
        ),
      );
    }

    return Stack(alignment: Alignment.center, children: slices);
  }
}

class _CategoryLegendItem extends StatelessWidget {
  const _CategoryLegendItem({required this.spend});

  final CategorySpend spend;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _colorOf(spend.category),
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                spend.category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatMad(spend.totalCents),
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
