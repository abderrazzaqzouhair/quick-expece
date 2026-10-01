import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../config/providers/database_providers.dart';
import 'add_expense_controller.dart';
import 'widgets/amount_input.dart';
import 'widgets/category_selector.dart';
import 'widgets/day_selector.dart';
import 'widgets/form_section.dart';
import 'widgets/subcategory_selector.dart';

/// Pushed full-screen (outside the tab shell) from the bottom nav's center
/// "create" button. Saves to the local database, then pops back.
///
/// Uses a plain `AppBar`, not `AppTopBar` — this is a pushed screen, not a
/// bottom-nav tab, so it needs the automatic back button.
class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final saved = await ref
          .read(addExpenseControllerProvider.notifier)
          .save(note: _noteController.text);
      if (!saved || !mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Expense added')));
      context.pop();
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not save the expense. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addExpenseControllerProvider);
    final controller = ref.read(addExpenseControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('New expense'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                AmountInput(
                  controller: _amountController,
                  onChanged: controller.setAmount,
                ),
                const SizedBox(height: 24),
                FormSection(
                  title: 'Category',
                  child: CategorySelector(
                    selectedId: state.categoryId,
                    onSelected: controller.selectCategory,
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: state.categoryId == null
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: FormSection(
                            title: 'Subcategory',
                            child: SubcategorySelector(
                              // Rebuild (and reset scroll/animation) per category.
                              key: ValueKey(state.categoryId),
                              categoryId: state.categoryId!,
                              accent: _accentFor(state.categoryId!),
                              selectedId: state.subcategoryId,
                              onSelected: controller.selectSubcategory,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                FormSection(
                  title: 'Date',
                  child: DaySelector(
                    day: state.day,
                    onChanged: controller.selectDay,
                  ),
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'Note (optional)',
                  hintText: 'e.g. Lunch with Sara',
                  prefixIcon: Icons.notes_rounded,
                  controller: _noteController,
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: AppPrimaryButton(
              label: 'Save expense',
              isLoading: state.isSaving,
              onPressed: state.canSave ? _save : null,
            ),
          ),
        ],
      ),
    );
  }

  /// The selected category's colour, reused to tint its subcategory chips.
  Color _accentFor(String categoryId) {
    final categories = ref.watch(selectedCategoriesProvider).value ?? [];
    for (final c in categories) {
      if (c.id == categoryId && c.color != null) {
        return HexColor.fromHex(c.color!);
      }
    }
    return AppColors.primary;
  }
}
