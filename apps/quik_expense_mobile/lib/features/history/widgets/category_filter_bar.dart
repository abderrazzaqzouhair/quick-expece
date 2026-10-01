import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../../shared/category_visuals.dart';
import '../../../shared/formatters.dart';
import '../../../shared/widgets/pressable.dart';
import '../logic/history_view.dart';
import '../../../shared/haptics.dart';

/// Horizontally scrolling chips: the month's categories, biggest spend
/// first, each with its total. Tap to filter; tap again to clear.
class CategoryFilterBar extends StatelessWidget {
  const CategoryFilterBar({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onTap,
  });

  final List<CategorySpend> categories;
  final String? selectedId;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final spend = categories[i];
          final category = spend.category;
          final color = CategoryVisuals.colorFor(category.color);
          final selected = category.id == selectedId;

          return Pressable(
            onTap: () {
              Haptics.selection();
              onTap(category.id);
            },
            semanticLabel:
                '${category.name}, ${formatMad(spend.totalCents)}'
                '${selected ? ', selected' : ''}',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.only(left: 6, right: 14),
              decoration: BoxDecoration(
                color: selected
                    ? color.withValues(alpha: 0.14)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected ? color : Colors.transparent,
                  width: 1.4,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CategoryAvatar(
                    name: category.name,
                    colorHex: category.color,
                    size: 30,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formatAmount(spend.totalCents),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
