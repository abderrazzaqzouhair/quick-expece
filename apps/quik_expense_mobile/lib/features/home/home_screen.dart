import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../config/router/app_routes.dart';

/// UI-only dashboard — every number below is mock data (no `expenses`/
/// `categories` provider wiring yet). Category names/colors are pulled from
/// the real `CategorySeeder` catalogue so the mock at least matches what
/// the backend actually seeds, rather than made-up categories.
///
/// There's no Income/Salary/Budget model in the backend (only Expense,
/// Category, Subcategory) — so unlike some reference finance-app designs,
/// this doesn't fabricate a "Total Salary" or a per-category budget target.
/// The two summary cards show the selected calendar day's spend (defaulting
/// to "Today", with an explicit "No expenses" state when nothing falls on
/// that day) next to that day's month total, and "Top Categories" ranks
/// real category totals instead of a made-up budget-vs-spend figure.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static final _categorySpend = [
    _CategorySpend(
      name: 'Food & Drinks',
      color: HexColor.fromHex('#F59E0B'),
      iconAsset: AppAssets.iconCategoryFood,
      amount: 450.00,
      monthlyDeltaPercent: 12,
    ),
    _CategorySpend(
      name: 'Transport',
      color: HexColor.fromHex('#3B82F6'),
      iconAsset: AppAssets.iconCategoryTransport,
      amount: 275.50,
      monthlyDeltaPercent: -8,
    ),
    _CategorySpend(
      name: 'Entertainment & Fun',
      color: HexColor.fromHex('#8B5CF6'),
      iconAsset: AppAssets.iconCategoryEntertainment,
      amount: 190.00,
      monthlyDeltaPercent: 22,
    ),
    _CategorySpend(
      name: 'Subscriptions & Digital',
      color: HexColor.fromHex('#6366F1'),
      iconAsset: AppAssets.iconCategorySubscriptions,
      amount: 132.75,
      monthlyDeltaPercent: -5,
    ),
  ];

  static final _today = DateTime.now();
  static final _recentExpenses = [
    _Transaction(
      category: _categorySpend[0],
      subcategory: 'Groceries',
      date: DateTime(_today.year, _today.month, _today.day, 9, 20),
      amount: 86.40,
    ),
    _Transaction(
      category: _categorySpend[1],
      subcategory: 'Ride-hailing',
      date: DateTime(_today.year, _today.month, _today.day, 14, 5),
      amount: 32.00,
    ),
    _Transaction(
      category: _categorySpend[2],
      subcategory: 'Streaming',
      date: DateTime(_today.year, _today.month, _today.day - 1, 20, 30),
      amount: 59.00,
    ),
    _Transaction(
      category: _categorySpend[3],
      subcategory: 'Music',
      date: DateTime(_today.year, _today.month, _today.day - 2, 11, 15),
      amount: 49.99,
    ),
  ];

  // In months, relative to the current one.
  int _monthOffset = 0;
  late DateTime _selectedDate = DateTime.now();

  double get _totalSpend => _categorySpend.fold(0, (sum, c) => sum + c.amount);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  /// The selected day's total, or `null` when no mock transaction falls on
  /// that day — the summary card shows an explicit "no expenses" state for
  /// that case rather than a misleading 0.00.
  double? get _selectedDaySpend {
    final matches = _recentExpenses.where(
      (t) => _isSameDay(t.date, _selectedDate),
    );
    if (matches.isEmpty) return null;
    return matches.fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  /// The total for the month the *selected day* falls in — not necessarily
  /// the month currently visible in the calendar grid, since tapping a
  /// dimmed padding day (from the previous/next month) should still switch
  /// the "This Month" card to reflect that day's month. There's no
  /// per-month mock breakdown, only the real current month's, so any other
  /// month renders the same "no expenses" empty state as an empty day.
  double? get _selectedMonthSpend {
    if (!_isSameMonth(_selectedDate, DateTime.now())) return null;
    return _totalSpend;
  }

  DateTime get _visibleMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month + _monthOffset);
  }

  /// The full month as a Monday-Sunday grid — padded with the tail end of
  /// the previous month and the start of the next so every row is a
  /// complete week, same as a standard calendar view.
  List<DateTime> get _visibleDays {
    final month = _visibleMonth;
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final lastOfMonth = DateTime(month.year, month.month + 1, 0);
    final gridStart = firstOfMonth.subtract(
      Duration(days: firstOfMonth.weekday - 1),
    );
    final totalDays = lastOfMonth.difference(gridStart).inDays + 1;
    final totalCells = (totalDays / 7).ceil() * 7;
    return List.generate(totalCells, (i) => gridStart.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final days = _visibleDays;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'Home',
        onProfileTap: () => context.go(AppRoutes.profile),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 20, 14, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WeekCalendarStrip(
              month: _visibleMonth,
              days: days,
              selectedDate: _selectedDate,
              onPreviousPeriod: () => setState(() => _monthOffset--),
              onNextPeriod: () => setState(() => _monthOffset++),
              onDaySelected: (date) => setState(() => _selectedDate = date),
            ),
            const SizedBox(height: 20),
            _SummaryCards(
              selectedDate: _selectedDate,
              selectedDaySpend: _selectedDaySpend,
              selectedMonthSpend: _selectedMonthSpend,
            ),
            const SizedBox(height: 20),
            _PremiumCard(
              child: _TopCategoriesCard(
                categories: _categorySpend,
                total: _totalSpend,
                onSeeAll: () => context.push(AppRoutes.categories),
              ),
            ),
            const SizedBox(height: 24),
            _SectionCard(
              child: _AnalyticsSection(
                categories: _categorySpend,
                total: _totalSpend,
                onSeeAll: () => context.go(AppRoutes.statistics),
              ),
            ),
            const SizedBox(height: 24),
            _SectionCard(
              child: _RecentExpensesSection(
                expenses: _recentExpenses,
                onSeeAll: () => context.go(AppRoutes.history),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySpend {
  const _CategorySpend({
    required this.name,
    required this.color,
    required this.iconAsset,
    required this.amount,
    required this.monthlyDeltaPercent,
  });

  final String name;
  final Color color;
  final String iconAsset;
  final double amount;

  /// Change vs last month, as a signed percentage. Mock/placeholder like
  /// the rest of this screen — the backend has no per-category historical
  /// aggregate to derive a real trend from yet; when one exists this is the
  /// field to wire it to.
  final int monthlyDeltaPercent;
}

class _Transaction {
  const _Transaction({
    required this.category,
    required this.subcategory,
    required this.date,
    required this.amount,
  });

  final _CategorySpend category;
  final String subcategory;
  final DateTime date;
  final double amount;
}

String _formatMad(double amount) =>
    '${NumberFormat('#,##0.00', 'en_US').format(amount)} MAD';

/// "Today" / "Yesterday" for the two most recent days, otherwise a plain
/// formatted date — same convention used across the recent-expenses list.
String _relativeDateLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final diff = today.difference(target).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return DateFormat.MMMd('en_US').format(date);
}

/// Calendar strip — every day of [month] as a real computed Monday-Sunday
/// grid (4-6 rows depending on the month), not a hardcoded fake date or a
/// fixed-length window. Padding days that spill into the previous/next
/// month are shown dimmed, same as a standard calendar view. Selecting a
/// day drives the left [_SummaryCard]'s day total (see
/// `_HomeScreenState._selectedDaySpend`); the recent-expenses/analytics
/// sections below are still unfiltered mock data (no `expenses` provider
/// wired yet).
class _WeekCalendarStrip extends StatelessWidget {
  const _WeekCalendarStrip({
    required this.month,
    required this.days,
    required this.selectedDate,
    required this.onPreviousPeriod,
    required this.onNextPeriod,
    required this.onDaySelected,
  });

  final DateTime month;
  final List<DateTime> days;
  final DateTime selectedDate;
  final VoidCallback onPreviousPeriod;
  final VoidCallback onNextPeriod;
  final ValueChanged<DateTime> onDaySelected;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

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
                  isSelected: _isSameDay(day, selectedDate),
                  isInVisibleMonth: day.month == month.month,
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
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final bool isInVisibleMonth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Padding days from the adjacent month are dimmed rather than hidden —
    // keeps every row a full week while making clear they're not "this
    // month", same as a standard calendar grid.
    final mutedOpacity = isInVisibleMonth ? 1.0 : 0.35;

    return InkWell(
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
              if (isSelected)
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                )
              else
                const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

/// Selected-day / selected-month cards. Orange for the day figure, a
/// derived charcoal tone for the month figure — a deliberate second neutral
/// tone instead of introducing an off-brand purple just to match a
/// reference image. Both labels and both amounts track [selectedDate] —
/// picking a day from an adjacent month (shown dimmed in the calendar grid)
/// switches the right card to that month too, not just the one currently
/// scrolled into view.
class _SummaryCards extends StatelessWidget {
  const _SummaryCards({
    required this.selectedDate,
    required this.selectedDaySpend,
    required this.selectedMonthSpend,
  });

  final DateTime selectedDate;
  final double? selectedDaySpend;
  final double? selectedMonthSpend;

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

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
            amount: selectedDaySpend,
            gradientColors: [AppColors.primaryLight, AppColors.primary],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: monthLabel,
            amount: selectedMonthSpend,
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
    required this.amount,
    required this.gradientColors,
  });

  final String label;
  // `null` renders a "no expenses" placeholder instead of an amount — the
  // selected-day card can legitimately have nothing to show.
  final double? amount;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
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
            child: Text(
              amount == null ? 'No expenses' : _formatMad(amount!),
              style: TextStyle(
                fontSize: amount == null ? 15 : 19,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(
                  alpha: amount == null ? 0.75 : 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Top Categories" — a horizontally scrolling row of category cards
/// (every category, not just a fixed top-3) instead of a static 3-column
/// row. Each [_PremiumCategoryCard] is a simple flat tile: solid pastel
/// wash of the category's real color, name, big price, and a one-line
/// percent readout underneath (share of spend for the top category, trend
/// vs last month otherwise) — see [_CategoryCardSurface]. Wrapped in a
/// bespoke floating [_PremiumCard] (28px radius/24px padding/large soft
/// shadow, separate from the shared [_SectionCard] used elsewhere) with its
/// own header type scale ([_PremiumSectionHeader]) and a spring press
/// animation on each card.
class _TopCategoriesCard extends StatelessWidget {
  const _TopCategoriesCard({
    required this.categories,
    required this.total,
    required this.onSeeAll,
  });

  final List<_CategorySpend> categories;
  final double total;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final ranked = [...categories]
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PremiumSectionHeader(title: 'Top Categories', onSeeAll: onSeeAll),
        const SizedBox(height: 24),
        if (ranked.isEmpty)
          const Text(
            'No expenses yet — your top categories will show up here.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          )
        else
          // A little taller than the card itself and unclipped, so each
          // card's own drop shadow has room to render — _PremiumCard's
          // own clip is the final guard against it bleeding past the
          // floating card's rounded corners.
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              clipBehavior: Clip.none,
              itemCount: ranked.length,
              separatorBuilder: (context, _) => const SizedBox(width: 14),
              itemBuilder: (context, i) => _PremiumCategoryCard(
                category: ranked[i],
                isLargest: i == 0,
                shareOfTotal: total == 0 ? 0 : ranked[i].amount / total,
              ),
            ),
          ),
        // Extra breathing room at the bottom so the section has a bit more
        // height without enlarging the tiles themselves.
        const SizedBox(height: 12),
      ],
    );
  }
}

/// Title (20px SemiBold near-black) and a "See all" action (muted accent
/// orange, 14px Medium, chevron, small tap animation) sharing a row.
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
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
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
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
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
    );
  }
}

/// A single category card with a physics-based spring press animation:
/// scales to 98%, deepens its shadow, and slightly strengthens its gradient
/// while pressed, then springs back on release.
class _PremiumCategoryCard extends StatefulWidget {
  const _PremiumCategoryCard({
    required this.category,
    required this.isLargest,
    required this.shareOfTotal,
  });

  final _CategorySpend category;
  final bool isLargest;
  final double shareOfTotal;

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

  // controller.value doubles as "press amount" (0 = rest, 1 = fully
  // pressed) rather than a literal scale — the spring targets 0 or 1 and
  // _CategoryCardSurface/the Transform.scale below interpolate from that.
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
    return GestureDetector(
      onTapDown: (_) => _animateTo(1),
      onTapUp: (_) => _animateTo(0),
      onTapCancel: () => _animateTo(0),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final pressT = _controller.value.clamp(0.0, 1.0);
          return Transform.scale(
            scale: 1 - (0.02 * pressT),
            child: _CategoryCardSurface(
              category: widget.category,
              isLargest: widget.isLargest,
              shareOfTotal: widget.shareOfTotal,
              pressT: pressT,
            ),
          );
        },
      ),
    );
  }
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// A plain white card: a tinted icon badge + category name on top, the big
/// amount, and a colored trend pill underneath. Neutral hairline border
/// (`#F1F3F5`) + a soft shadow for depth — a saturated colored border reads
/// as an AI-mockup tell in a finance app, where premium apps (Wallet,
/// Revolut) keep the card chrome neutral and let the pill be the only spot
/// of strong color.
class _CategoryCardSurface extends StatelessWidget {
  const _CategoryCardSurface({
    required this.category,
    required this.isLargest,
    required this.shareOfTotal,
    required this.pressT,
  });

  final _CategorySpend category;
  final bool isLargest;
  final double shareOfTotal;
  final double pressT;

  // iOS system green/red — spend down vs last month is "good" (green), up is
  // "watch out" (red). The accent star pill covers the leader instead.
  static const _trendDown = Color(0xFF2FB457);
  static const _trendUp = Color(0xFFE5484D);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 176,
      height: 128,
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
              AppIconBadge(
                assetPath: category.iconAsset,
                color: category.color,
                backgroundAlpha: 0.12,
                size: 26,
                iconSize: 15,
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
                  text: NumberFormat('#,##0', 'en_US').format(category.amount),
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

    if (isLargest) {
      icon = Icons.star_rounded;
      color = category.color;
      label = '${(shareOfTotal * 100).round()}% of spend';
    } else {
      final delta = category.monthlyDeltaPercent;
      final isUp = delta >= 0;
      icon = isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
      color = isUp ? _trendUp : _trendDown;
      label = '${delta.abs()}% vs last mo.';
    }

    // Filled pill: light tint of the trend color behind icon + label —
    // matches the "↘ 8%" / "↗ 8%" chips on the summary cards.
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
/// large soft low-opacity shadow — distinct from the flatter, tighter
/// [_SectionCard] used by the other Home sections.
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

/// Shows at most [_maxVisible] of the most recent expenses — "Recent" means
/// recent, not the whole history; "See All" is the way to the full list.
/// Each row surfaces exactly what was asked for: icon, category,
/// subcategory, time, and amount — no free-text merchant note competing for
/// attention with them.
class _RecentExpensesSection extends StatelessWidget {
  const _RecentExpensesSection({
    required this.expenses,
    required this.onSeeAll,
  });

  static const _maxVisible = 4;

  final List<_Transaction> expenses;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final visible = expenses.take(_maxVisible).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PremiumSectionHeader(title: 'Recent Expenses', onSeeAll: onSeeAll),
        const SizedBox(height: 4),
        if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No expenses yet.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          )
        else
          for (final transaction in visible)
            _TransactionRow(transaction: transaction),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final _Transaction transaction;

  /// "9:20 AM" for today's entries; "Yesterday, 8:30 PM" otherwise — the
  /// bare time alone would be ambiguous once the list spans several days.
  String _timeLabel(DateTime date) {
    final time = DateFormat.jm('en_US').format(date);
    final day = _relativeDateLabel(date);
    return day == 'Today' ? time : '$day, $time';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppIconBadge(
            assetPath: transaction.category.iconAsset,
            color: transaction.category.color,
            backgroundColor: Colors.white,
            border: Border.all(color: AppColors.border),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.category.name,
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
                  transaction.subcategory,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-${_formatMad(transaction.amount)}',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _timeLabel(transaction.date),
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Info list on the left (dot, category name, amount — stacked, one row per
/// category), a real *exploded* pie on the right — each wedge physically
/// pulled apart from the others, like the reference image, not just
/// outlined.
///
/// fl_chart has no built-in "explode" option (that's a Syncfusion-only
/// feature among maintained packages — `pie_chart_3d` looked promising but
/// is unverified/low-adoption and doesn't actually support slice
/// separation), so this fakes it with a well-known trick: render one full
/// circular [PieChart] per category with every *other* category's section
/// made transparent, then [Transform.translate] each of those full circles
/// outward along its own slice's bisecting angle. Stacked together, only
/// the real per-slice color and position show through, and the small
/// per-slice translation creates a genuine gap between wedges instead of
/// just a border line. The angle math only depends on values this widget
/// already has (category amounts + `startDegreeOffset: -90`, matching
/// fl_chart's own clockwise-from-12-o'clock convention), not on any
/// internal fl_chart pixel geometry, so it's safe to compute directly.
class _AnalyticsSection extends StatelessWidget {
  const _AnalyticsSection({
    required this.categories,
    required this.total,
    required this.onSeeAll,
  });

  final List<_CategorySpend> categories;
  final double total;
  final VoidCallback onSeeAll;

  static const _chartSize = 150.0;
  static const _explodeDistance = 9.0;

  @override
  Widget build(BuildContext context) {
    final top4 = categories.take(4).toList();
    final sum = top4.fold(0.0, (s, c) => s + c.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PremiumSectionHeader(title: 'Analytics', onSeeAll: onSeeAll),
        const SizedBox(height: 20),
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
                      child: _CategoryLegendItem(category: top4[i]),
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

  Widget _buildExplodedPie(List<_CategorySpend> top4, double sum) {
    var cumulativeDegrees = 0.0;
    final slices = <Widget>[];

    for (var i = 0; i < top4.length; i++) {
      final sweep = sum == 0 ? 360.0 / top4.length : top4[i].amount / sum * 360;
      final midAngleRad = (-90 + cumulativeDegrees + sweep / 2) * math.pi / 180;
      cumulativeDegrees += sweep;

      slices.add(
        Transform.translate(
          offset: Offset(
            math.cos(midAngleRad) * _explodeDistance,
            math.sin(midAngleRad) * _explodeDistance,
          ),
          // No shadow here: this circle is transparent everywhere except
          // the one visible wedge, so a boxShadow on it shadows the whole
          // invisible circle bounding box, not the wedge's actual shape —
          // that's the diffuse colored halo the user was seeing.
          child: PieChart(
            PieChartData(
              sections: [
                for (var j = 0; j < top4.length; j++)
                  PieChartSectionData(
                    value: top4[j].amount,
                    color: i == j ? top4[j].color : Colors.transparent,
                    radius: 72,
                    showTitle: i == j,
                    title: total == 0
                        ? '0%'
                        : '${(top4[j].amount / total * 100).round()}%',
                    titleStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    titlePositionPercentageOffset: 0.62,
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
  const _CategoryLegendItem({required this.category});

  final _CategorySpend category;

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
              color: category.color,
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
                category.name,
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
                _formatMad(category.amount),
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
