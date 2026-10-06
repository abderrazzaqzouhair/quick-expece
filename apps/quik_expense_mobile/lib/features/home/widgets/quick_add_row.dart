import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../../shared/category_visuals.dart';
import '../../../shared/widgets/pressable.dart';
import '../logic/home_extras.dart';

/// "Quick add" — your most-used subcategories as chips. Tapping one opens
/// Add Expense with that category already picked.
class QuickAddRow extends StatelessWidget {
  const QuickAddRow({super.key, required this.items, required this.onTap});

  final List<QuickAddItem> items;
  final ValueChanged<QuickAddItem> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              Icon(Icons.bolt_rounded, size: 18, color: AppColors.primary),
              SizedBox(width: 4),
              Text(
                'Quick add',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 46,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final item = items[i];
              return Pressable(
                onTap: () => onTap(item),
                semanticLabel: 'Add ${item.subcategory.name} expense',
                child: Container(
                  padding: const EdgeInsets.only(left: 6, right: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(23),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CategoryAvatar(
                        name: item.category.name,
                        colorHex: item.category.color,
                        size: 34,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.subcategory.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
