import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../../shared/formatters.dart';
import '../../../shared/haptics.dart';
import '../logic/period_stats.dart';
import '../logic/trend_labels.dart';

/// "Spending Trend" on a dark card: one gradient pill bar per bucket (day,
/// week, month… depending on the period), a white bubble with the selected
/// bar's amount, and round label chips underneath. Tap a bar to select it;
/// the current bucket is selected by default. Key it per period so the
/// selection resets.
class TrendCard extends StatefulWidget {
  const TrendCard({super.key, required this.stats});

  final PeriodStats stats;

  @override
  State<TrendCard> createState() => _TrendCardState();
}

class _TrendCardState extends State<TrendCard> {
  late int _selected = _defaultIndex();

  /// The bucket containing "now", else the latest one that has started.
  int _defaultIndex() {
    final buckets = widget.stats.buckets;
    final now = widget.stats.now;
    final current = buckets.indexWhere((b) => b.isCurrent(now));
    if (current != -1) return current;
    final started = buckets.lastIndexWhere((b) => !b.isFuture(now));
    return started == -1 ? 0 : started;
  }

  @override
  void didUpdateWidget(TrendCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selected >= widget.stats.buckets.length) _selected = _defaultIndex();
  }

  void _select(int i) {
    if (i == _selected) return;
    Haptics.selection();
    setState(() => _selected = i);
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;
    if (stats.buckets.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF232326), Color(0xFF121214)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Text(
                  'Spending Trend',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  windowLabel(stats.period, stats),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _Summary(stats: stats),
          const SizedBox(height: 18),
          SizedBox(
            height: 230 * MediaQuery.textScalerOf(context).scale(1),
            child: _Bars(stats: stats, selected: _selected, onSelect: _select),
          ),
        ],
      ),
    );
  }
}

/// "772.50 MAD total · ↑ 32% vs last month".
class _Summary extends StatelessWidget {
  const _Summary({required this.stats});

  final PeriodStats stats;

  @override
  Widget build(BuildContext context) {
    final delta = stats.deltaPercent;
    final phrase = comparisonPhrase(stats.period);
    final muted = Colors.white.withValues(alpha: 0.6);

    return Text.rich(
      TextSpan(
        style: TextStyle(fontSize: 12.5, color: muted),
        children: [
          TextSpan(
            text: formatMad(stats.totalCents),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const TextSpan(text: ' total'),
          if (phrase != null && delta != null) ...[
            const TextSpan(text: '  ·  '),
            TextSpan(
              text: '${delta >= 0 ? '↑' : '↓'} ${delta.abs()}% ',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: delta >= 0
                    ? const Color(0xFFFF6B6B)
                    : const Color(0xFF4ADE80),
              ),
            ),
            TextSpan(text: phrase),
          ],
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _Bars extends StatelessWidget {
  const _Bars({
    required this.stats,
    required this.selected,
    required this.onSelect,
  });

  final PeriodStats stats;
  final int selected;
  final ValueChanged<int> onSelect;

  static const _chipSize = 34.0;
  static const _chipGap = 12.0;
  static const _bubbleWidth = 104.0;
  static const _bubbleHeight = 46.0;

  @override
  Widget build(BuildContext context) {
    final buckets = stats.buckets;
    final maxCents = buckets.fold(0, (m, b) => math.max(m, b.totalCents));

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final slot = width / buckets.length;
        final barWidth = math.min(30.0, slot * 0.62);
        // Leave room above the tallest bar for the bubble.
        final barArea =
            constraints.maxHeight - _chipSize - _chipGap - _bubbleHeight - 10;

        double barHeight(int i) {
          final cents = buckets[i].totalCents;
          if (cents == 0 || maxCents == 0) return 10;
          return math.max(14, cents / maxCents * barArea);
        }

        final sel = selected.clamp(0, buckets.length - 1);
        final selCenter = slot * (sel + 0.5);
        final bubbleLeft = (selCenter - _bubbleWidth / 2)
            .clamp(0.0, math.max(0.0, width - _bubbleWidth))
            .toDouble();
        // The bubble lives in the free band above every bar (never covering a
        // neighbour); a thin line drops from its pointer to the selected bar.
        final barsBase = _chipSize + _chipGap;
        final bubbleBottom = barsBase + barArea + 10;
        final selTop = barsBase + barHeight(sel);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < buckets.length; i++)
                  Expanded(
                    child: _BarColumn(
                      bucket: buckets[i],
                      label: axisLabel(stats.period, buckets[i]),
                      barHeight: barHeight(i),
                      barWidth: barWidth,
                      chipSize: math.min(_chipSize, slot - 4),
                      chipGap: _chipGap,
                      isSelected: i == sel,
                      isFuture: buckets[i].isFuture(stats.now),
                      onTap: () => onSelect(i),
                    ),
                  ),
              ],
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              left: selCenter - 0.75,
              bottom: selTop + 4,
              width: 1.5,
              height: math.max(0, bubbleBottom - selTop - 4),
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.5),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              left: bubbleLeft,
              bottom: bubbleBottom,
              width: _bubbleWidth,
              child: IgnorePointer(
                child: _Bubble(
                  amount: formatMad(buckets[sel].totalCents),
                  caption: bucketCaption(stats.period, buckets[sel]),
                  // Pointer stays over the bar even when the bubble is
                  // pushed in from the card edge.
                  pointerX: (selCenter - bubbleLeft).clamp(
                    12.0,
                    _bubbleWidth - 12,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BarColumn extends StatelessWidget {
  const _BarColumn({
    required this.bucket,
    required this.label,
    required this.barHeight,
    required this.barWidth,
    required this.chipSize,
    required this.chipGap,
    required this.isSelected,
    required this.isFuture,
    required this.onTap,
  });

  final StatsBucket bucket;
  final String label;
  final double barHeight;
  final double barWidth;
  final double chipSize;
  final double chipGap;
  final bool isSelected;
  final bool isFuture;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasSpend = bucket.totalCents > 0;
    final Decoration barDecoration;
    if (isFuture || !hasSpend) {
      barDecoration = BoxDecoration(
        color: Colors.white.withValues(alpha: isFuture ? 0.05 : 0.10),
        borderRadius: BorderRadius.circular(barWidth),
      );
    } else {
      // Bright orange at the top fading into the dark card.
      barDecoration = BoxDecoration(
        borderRadius: BorderRadius.circular(barWidth),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isSelected
              ? const [Color(0xFFFFA05C), AppColors.primary, Color(0xFF5A2208)]
              : [
                  AppColors.primary.withValues(alpha: 0.95),
                  const Color(0xFFB8470A).withValues(alpha: 0.75),
                  const Color(0xFF2A1408).withValues(alpha: 0.6),
                ],
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  blurRadius: 18,
                ),
              ]
            : null,
      );
    }

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${bucket.label}: ${formatMad(bucket.totalCents)}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // the whole column is tappable
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              height: barHeight,
              width: barWidth,
              decoration: barDecoration,
            ),
            SizedBox(height: chipGap),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: chipSize,
              height: chipSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.08),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? const Color(0xFFFFA05C)
                          : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// White rounded bubble with a small pointer, like a chart tooltip.
class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.amount,
    required this.caption,
    required this.pointerX,
  });

  final String amount;
  final String caption;
  final double pointerX;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: 1),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  caption,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: pointerX - 6),
          child: CustomPaint(
            size: const Size(12, 6),
            painter: _PointerPainter(),
          ),
        ),
      ],
    );
  }
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_PointerPainter oldDelegate) => false;
}
