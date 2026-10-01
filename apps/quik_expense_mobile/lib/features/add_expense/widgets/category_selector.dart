import 'package:database/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../../config/providers/database_providers.dart';
import 'selectable_chip.dart';

/// The user's selected categories as colour-coded chips.
class CategorySelector extends ConsumerWidget {
  const CategorySelector({
    super.key,
    required this.selectedId,
    required this.onSelected,
  });

  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(selectedCategoriesProvider)
        .when(
          loading: () => const _ChipsPlaceholder(),
          error: (error, stack) {
            debugPrint('Failed to load categories: $error\n$stack');
            return const Text(
              'Could not load categories.',
              style: TextStyle(color: AppColors.error),
            );
          },
          data: (categories) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in categories)
                SelectableChip(
                  label: category.name,
                  selected: category.id == selectedId,
                  accent: _colorOf(category),
                  showDot: true,
                  onTap: () => onSelected(category.id),
                ),
            ],
          ),
        );
  }

  static Color _colorOf(CategoryRow category) => category.color == null
      ? AppColors.primary
      : HexColor.fromHex(category.color!);
}

class _ChipsPlaceholder extends StatelessWidget {
  const _ChipsPlaceholder();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 40,
    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
  );
}
