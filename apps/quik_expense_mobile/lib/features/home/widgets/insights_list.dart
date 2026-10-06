import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

import '../logic/home_extras.dart';

/// Short auto-generated observations, each with a tinted icon and its key
/// figure in bold.
class InsightsList extends StatelessWidget {
  const InsightsList({super.key, required this.insights});

  final List<Insight> insights;

  static (IconData, Color) _visual(InsightKind kind) => switch (kind) {
    InsightKind.projection => (Icons.speed_rounded, const Color(0xFF3B82F6)),
    InsightKind.categoryUp => (
      Icons.trending_up_rounded,
      const Color(0xFFE5484D),
    ),
    InsightKind.categoryDown => (
      Icons.trending_down_rounded,
      const Color(0xFF2FB457),
    ),
    InsightKind.biggest => (Icons.receipt_long_rounded, AppColors.primary),
    InsightKind.noSpendDays => (
      Icons.emoji_events_rounded,
      const Color(0xFF2FB457),
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < insights.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          _InsightRow(insight: insights[i], visual: _visual(insights[i].kind)),
        ],
      ],
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.insight, required this.visual});

  final Insight insight;
  final (IconData, Color) visual;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = visual;
    final text = insight.text;
    final at = text.indexOf(insight.highlight);
    const base = TextStyle(
      fontSize: 14,
      height: 1.4,
      color: AppColors.textPrimary,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 19, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 7),
            child: at < 0
                ? Text(text, style: base)
                : Text.rich(
                    TextSpan(
                      style: base,
                      children: [
                        TextSpan(text: text.substring(0, at)),
                        TextSpan(
                          text: insight.highlight,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: text.substring(at + insight.highlight.length),
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
