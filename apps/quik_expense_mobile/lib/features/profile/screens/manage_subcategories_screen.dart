import 'package:database/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../../config/providers/database_providers.dart';
import '../../../shared/category_visuals.dart';
import '../../../shared/haptics.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/settings_list.dart';
import '../data/profile_providers.dart';

/// One category: show/hide it, and pick which of its subcategories appear
/// in the add-expense picker. A visible category keeps at least one
/// visible subcategory (otherwise its picker page would be empty).
class ManageSubcategoriesScreen extends ConsumerWidget {
  const ManageSubcategoriesScreen({super.key, required this.categoryId});

  final String categoryId;

  void _warn(BuildContext context, String message) {
    Haptics.heavy();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(appToast(message));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(allCategoriesProvider).value;
    final allSubs = ref.watch(allSubcategoriesProvider).value;
    final db = ref.read(appDatabaseProvider);

    final category = categories?.where((c) => c.id == categoryId).firstOrNull;
    if (category == null || allSubs == null) {
      return const SettingsScaffold(
        title: 'Subcategories',
        children: [AppSkeleton(child: SkeletonBox(height: 420, radius: 18))],
      );
    }

    final subs = allSubs.where((s) => s.categoryId == categoryId).toList();
    final visibleSubs = subs.where((s) => s.isSelected).length;
    final visibleCategories = categories!.where((c) => c.isSelected).length;

    Future<void> toggleCategory(bool show) async {
      if (!show && visibleCategories <= 1) {
        return _warn(context, 'Keep at least one category visible.');
      }
      Haptics.selection();
      await db.categoriesDao.setSelected(category.id, selected: show);
    }

    Future<void> toggleSub(SubcategoryRow sub, bool show) async {
      if (!show && visibleSubs <= 1 && category.isSelected) {
        return _warn(
          context,
          'Keep at least one subcategory, or hide the whole category.',
        );
      }
      Haptics.selection();
      await db.subcategoriesDao.setSelected(sub.id, selected: show);
    }

    return SettingsScaffold(
      title: category.name,
      children: [
        Center(
          child: CategoryAvatar(
            name: category.name,
            colorHex: category.color,
            size: 72,
          ),
        ),
        const SizedBox(height: 24),
        SettingsGroup(
          children: [
            SettingsTile(
              icon: CategoryVisuals.iconFor(category.name),
              iconColor: CategoryVisuals.colorFor(category.color),
              title: 'Show this category',
              trailing: SettingsSwitch(
                value: category.isSelected,
                onChanged: toggleCategory,
              ),
            ),
          ],
        ),
        AnimatedOpacity(
          opacity: category.isSelected ? 1 : 0.45,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: !category.isSelected,
            child: SettingsGroup(
              title: '$visibleSubs of ${subs.length} subcategories shown',
              children: [
                for (final sub in subs)
                  _SubRow(
                    sub: sub,
                    color: CategoryVisuals.colorFor(category.color),
                    onChanged: (show) => toggleSub(sub, show),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SubRow extends StatelessWidget {
  const _SubRow({
    required this.sub,
    required this.color,
    required this.onChanged,
  });

  final SubcategoryRow sub;
  final Color color;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!sub.isSelected),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(left: 11, right: 25),
                decoration: BoxDecoration(
                  color: sub.isSelected ? color : AppColors.border,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  sub.name,
                  style: TextStyle(
                    fontSize: 15.5,
                    color: sub.isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              Semantics(
                label: 'Show ${sub.name}',
                child: SettingsSwitch(
                  value: sub.isSelected,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
