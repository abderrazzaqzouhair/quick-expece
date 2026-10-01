import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// Pill-shaped single-choice chip. Tinted with [accent] when selected; an
/// optional colour dot identifies the category.
class SelectableChip extends StatelessWidget {
  const SelectableChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.accent = AppColors.primary,
    this.showDot = false,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;
  final bool showDot;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? accent.withValues(alpha: 0.12) : AppColors.surface,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? accent : AppColors.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showDot) ...[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: selected ? accent : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: AppColors.textPrimary,
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
