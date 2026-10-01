import 'package:database/database.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../../shared/category_visuals.dart';
import '../../../shared/widgets/pressable.dart';

/// The main "what was it for" control under the amount. Empty: an inviting
/// prompt. Chosen: the category tile + subcategory/category names.
class CategoryField extends StatelessWidget {
  const CategoryField({
    super.key,
    required this.category,
    required this.subcategory,
    required this.onTap,
    this.highlight = false,
  });

  final CategoryRow? category;
  final SubcategoryRow? subcategory;
  final VoidCallback onTap;

  /// Draws attention when it's the next thing to fill in.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final chosen = category != null && subcategory != null;

    return Pressable(
      onTap: onTap,
      semanticLabel: chosen
          ? 'Category: ${subcategory!.name}, ${category!.name}. Change'
          : 'Choose a category',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: highlight
                ? AppColors.primary.withValues(alpha: 0.55)
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            if (chosen)
              CategoryAvatar(name: category!.name, colorHex: category!.color)
            else
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    chosen ? subcategory!.name : 'Choose category',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    chosen ? category!.name : 'What did you spend on?',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact capsule for secondary details (date, note).
class DetailPill extends StatelessWidget {
  const DetailPill({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSet = false,
    this.semanticLabel,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Filled (tinted) once the user has set a value.
  final bool isSet;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: semanticLabel ?? label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSet
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 17,
              color: isSet ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSet ? AppColors.secondary : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
