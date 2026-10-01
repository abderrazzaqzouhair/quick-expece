import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../../config/providers/database_providers.dart';
import 'selectable_chip.dart';

/// Subcategories of [categoryId] as chips, tinted with the category colour.
class SubcategorySelector extends ConsumerWidget {
  const SubcategorySelector({
    super.key,
    required this.categoryId,
    required this.accent,
    required this.selectedId,
    required this.onSelected,
  });

  final String categoryId;
  final Color accent;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(selectedSubcategoriesProvider(categoryId))
        .when(
          loading: () => const SizedBox(height: 40),
          error: (error, stack) {
            debugPrint('Failed to load subcategories: $error\n$stack');
            return const Text(
              'Could not load subcategories.',
              style: TextStyle(color: AppColors.error),
            );
          },
          data: (subcategories) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final sub in subcategories)
                SelectableChip(
                  label: sub.name,
                  selected: sub.id == selectedId,
                  accent: accent,
                  onTap: () => onSelected(sub.id),
                ),
            ],
          ),
        );
  }
}
