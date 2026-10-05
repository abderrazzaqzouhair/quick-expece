import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../features/statistics/logic/period_stats.dart';

/// iOS-style segmented control: a light track with a white sliding pill
/// behind the selected period. Shared by Statistics and the expense list
/// screen so both pick a period the same way.
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final StatsPeriod selected;
  final ValueChanged<StatsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final period in StatsPeriod.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: period == selected,
                label: period.label,
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(period),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: period == selected
                          ? AppColors.surface
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: period == selected
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      period.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: period == selected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
