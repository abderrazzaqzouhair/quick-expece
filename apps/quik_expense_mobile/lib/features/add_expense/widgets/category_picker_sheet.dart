import 'package:database/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../../config/providers/database_providers.dart';
import '../../../shared/category_visuals.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/haptics.dart';

/// What the picker returns.
typedef CategoryChoice = ({CategoryRow category, SubcategoryRow subcategory});

/// Opens the two-step picker: category grid → subcategory list. If a
/// category is already chosen it opens straight on its subcategories (the
/// common "change subcategory" case), with a back button to all categories.
Future<CategoryChoice?> showCategoryPicker(
  BuildContext context, {
  CategoryRow? initialCategory,
  SubcategoryRow? initialSubcategory,
}) {
  return showAppSheet<CategoryChoice>(
    context,
    builder: (_) => _CategoryPickerSheet(
      initialCategory: initialCategory,
      selectedSubcategoryId: initialSubcategory?.id,
    ),
  );
}

class _CategoryPickerSheet extends StatefulWidget {
  const _CategoryPickerSheet({
    this.initialCategory,
    this.selectedSubcategoryId,
  });

  final CategoryRow? initialCategory;
  final String? selectedSubcategoryId;

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  late CategoryRow? _category = widget.initialCategory;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.74;
    final category = _category;

    return SizedBox(
      height: height,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          // Subcategories slide in from the right; the grid from the left.
          final isList = child.key == const ValueKey('list');
          final begin = Offset(isList ? 0.25 : -0.25, 0);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: begin,
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: category == null
            ? _CategoryGrid(
                key: const ValueKey('grid'),
                selectedId: widget.initialCategory?.id,
                onSelected: (c) {
                  Haptics.selection();
                  setState(() => _category = c);
                },
              )
            : _SubcategoryList(
                key: const ValueKey('list'),
                category: category,
                selectedId: category.id == widget.initialCategory?.id
                    ? widget.selectedSubcategoryId
                    : null,
                onBack: () => setState(() => _category = null),
                onSelected: (sub) {
                  Haptics.light();
                  Navigator.of(
                    context,
                  ).pop<CategoryChoice>((category: category, subcategory: sub));
                },
              ),
      ),
    );
  }
}

class _CategoryGrid extends ConsumerWidget {
  const _CategoryGrid({
    super.key,
    required this.selectedId,
    required this.onSelected,
  });

  final String? selectedId;
  final ValueChanged<CategoryRow> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        AppSheetHeader(
          title: 'Category',
          trailing: SheetTextButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              final categories = ref.watch(selectedCategoriesProvider);
              if (categories.hasError && !categories.hasValue) {
                debugPrint('Failed to load categories: ${categories.error}');
                return const _ErrorText('Could not load categories.');
              }
              final items = categories.value;
              return SkeletonSwitcher(
                isLoading: items == null,
                skeleton: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: _gridPadding,
                  gridDelegate: _gridDelegate(context),
                  itemCount: 9,
                  itemBuilder: (_, _) => const _CategoryTileSkeleton(),
                ),
                child: GridView.builder(
                  padding: _gridPadding,
                  gridDelegate: _gridDelegate(context),
                  itemCount: items?.length ?? 0,
                  itemBuilder: (context, i) => _CategoryTile(
                    category: items![i],
                    selected: items[i].id == selectedId,
                    onTap: () => onSelected(items[i]),
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

const _gridPadding = EdgeInsets.fromLTRB(16, 4, 16, 24);

/// Fixed tile height (avatar + paddings + two text lines) that grows with
/// the system text size, so names never clip. Shared with the skeleton so
/// the two grids line up exactly.
SliverGridDelegate _gridDelegate(BuildContext context) =>
    SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      mainAxisExtent: 86 + 2 * MediaQuery.textScalerOf(context).scale(16),
    );

/// Placeholder tile: real white card, shimmering avatar + name lines.
class _CategoryTileSkeleton extends StatelessWidget {
  const _CategoryTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const AppSkeleton(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SkeletonBox(width: 48, height: 48, radius: 14),
            SizedBox(height: 12),
            SkeletonBox(width: 64, height: 10, radius: 5),
            SizedBox(height: 6),
            SkeletonBox(width: 40, height: 10, radius: 5),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final CategoryRow category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = CategoryVisuals.colorFor(category.color);
    return Pressable(
      onTap: onTap,
      semanticLabel: category.name,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.6,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CategoryAvatar(
              name: category.name,
              colorHex: category.color,
              size: 48,
            ),
            const SizedBox(height: 10),
            Text(
              category.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.25,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubcategoryList extends ConsumerWidget {
  const _SubcategoryList({
    super.key,
    required this.category,
    required this.selectedId,
    required this.onBack,
    required this.onSelected,
  });

  final CategoryRow category;
  final String? selectedId;
  final VoidCallback onBack;
  final ValueChanged<SubcategoryRow> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = CategoryVisuals.colorFor(category.color);

    return Column(
      children: [
        AppSheetHeader(
          title: category.name,
          leading: TextButton.icon(
            onPressed: onBack,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: const Size(44, 44),
            ),
            icon: const Icon(Icons.chevron_left_rounded, size: 26),
            label: const Text('All', style: TextStyle(fontSize: 17)),
          ),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              final subs = ref.watch(
                selectedSubcategoriesProvider(category.id),
              );
              if (subs.hasError && !subs.hasValue) {
                debugPrint('Failed to load subcategories: ${subs.error}');
                return const _ErrorText('Could not load subcategories.');
              }
              final items = subs.value;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Center(
                      child: CategoryAvatar(
                        name: category.name,
                        colorHex: category.color,
                        size: 64,
                      ),
                    ),
                  ),
                  SkeletonSwitcher(
                    isLoading: items == null,
                    skeleton: const _SubcategoryListSkeleton(),
                    child: GroupedCard(
                      children: [
                        for (final sub in items ?? const <SubcategoryRow>[])
                          _SubcategoryRow(
                            name: sub.name,
                            color: color,
                            selected: sub.id == selectedId,
                            onTap: () => onSelected(sub),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Placeholder grouped list: real white card, shimmering rows.
class _SubcategoryListSkeleton extends StatelessWidget {
  const _SubcategoryListSkeleton();

  static const _widths = [96.0, 72.0, 118.0, 84.0, 104.0, 64.0];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: AppSkeleton(
        child: Column(
          children: [
            for (final width in _widths)
              SizedBox(
                height: 52,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const SkeletonBox(width: 8, height: 8, circle: true),
                      const SizedBox(width: 12),
                      SkeletonBox(width: width, height: 13, radius: 6),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SubcategoryRow extends StatelessWidget {
  const _SubcategoryRow({
    required this.name,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                // Picker, not navigation: only the current choice gets a mark.
                if (selected)
                  const Icon(
                    Icons.check_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(message, style: const TextStyle(color: AppColors.error)),
  );
}
