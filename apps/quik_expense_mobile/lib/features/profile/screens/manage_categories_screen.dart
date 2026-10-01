import 'package:database/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../../config/providers/database_providers.dart';
import '../../../config/router/app_routes.dart';
import '../../../shared/category_visuals.dart';
import '../../../shared/haptics.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/settings_list.dart';
import '../data/profile_providers.dart';

/// Show / hide categories in the add-expense picker; tap one to manage its
/// subcategories. At least one category always stays visible.
class ManageCategoriesScreen extends ConsumerWidget {
  const ManageCategoriesScreen({super.key});

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    CategoryRow category,
    bool show,
    int visibleCount,
  ) async {
    if (!show && visibleCount <= 1) {
      Haptics.heavy();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(appToast('Keep at least one category visible.'));
      return;
    }
    Haptics.selection();
    await ref
        .read(appDatabaseProvider)
        .categoriesDao
        .setSelected(category.id, selected: show);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(allCategoriesProvider).value;
    final subs = ref.watch(allSubcategoriesProvider).value;

    if (categories == null || subs == null) {
      return const SettingsScaffold(
        title: 'Categories',
        children: [
          AppSkeleton(
            child: Column(
              children: [
                SkeletonBox(height: 72, radius: 18),
                SizedBox(height: 24),
                SkeletonBox(height: 480, radius: 18),
              ],
            ),
          ),
        ],
      );
    }

    final visible = categories.where((c) => c.isSelected).length;

    return SettingsScaffold(
      title: 'Categories',
      children: [
        _SummaryCard(visible: visible, total: categories.length),
        const SizedBox(height: 24),
        SettingsGroup(
          title: 'Your categories',
          footer:
              'Hidden categories won\'t appear when you add an expense. '
              'Past expenses keep their category.',
          children: [
            for (final category in categories)
              _CategoryRow(
                category: category,
                subsShown: subs
                    .where((s) => s.categoryId == category.id && s.isSelected)
                    .length,
                subsTotal: subs
                    .where((s) => s.categoryId == category.id)
                    .length,
                onToggle: (show) =>
                    _toggle(context, ref, category, show, visible),
                onTap: () =>
                    context.push(AppRoutes.profileSubcategories(category.id)),
              ),
          ],
        ),
        if (visible < categories.length || subs.any((s) => !s.isSelected))
          SettingsGroup(
            children: [
              SettingsTile(
                icon: Icons.visibility_rounded,
                iconColor: const Color(0xFF34C759),
                title: 'Show everything again',
                showChevron: false,
                onTap: () async {
                  Haptics.medium();
                  await ref.read(dataActionsProvider).showAllCategories();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      appToast(
                        'All categories are visible',
                        kind: ToastKind.success,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.visible, required this.total});

  final int visible;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [AppColors.primaryLight, AppColors.primary],
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.grid_view_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$visible of $total shown',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hide what you never use to add expenses faster.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.subsShown,
    required this.subsTotal,
    required this.onToggle,
    required this.onTap,
  });

  final CategoryRow category;
  final int subsShown;
  final int subsTotal;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          child: Row(
            children: [
              AnimatedOpacity(
                opacity: category.isSelected ? 1 : 0.4,
                duration: const Duration(milliseconds: 200),
                child: CategoryAvatar(
                  name: category.name,
                  colorHex: category.color,
                  size: 36,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w500,
                        color: category.isSelected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category.isSelected
                          ? '$subsShown of $subsTotal subcategories'
                          : 'Hidden',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Semantics(
                label: 'Show ${category.name}',
                child: SettingsSwitch(
                  value: category.isSelected,
                  onChanged: onToggle,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
