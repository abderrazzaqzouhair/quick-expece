import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../shared/formatters.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/pressable.dart';
import 'add_expense_controller.dart';
import 'logic/amount_entry.dart';
import 'widgets/amount_display.dart';
import 'widgets/amount_keypad.dart';
import 'widgets/category_picker_sheet.dart';
import 'widgets/date_sheet.dart';
import 'widgets/detail_pills.dart';
import 'widgets/note_sheet.dart';
import 'widgets/save_button.dart';
import '../../shared/haptics.dart';

/// Pushed full-screen from the bottom nav's center "create" button.
///
/// One-screen, keyboard-free flow (Apple Cash style): big live amount →
/// built-in keypad → category sheet → save. Date and note are optional
/// pills. The save button names the next missing step and acts on it.
class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  int _shake = 0;

  AddExpenseController get _controller =>
      ref.read(addExpenseControllerProvider.notifier);

  void _onKey(AmountKey key) {
    if (!_controller.pressKey(key)) _rejectAmount();
  }

  void _rejectAmount() {
    Haptics.heavy();
    setState(() => _shake++);
  }

  Future<void> _pickCategory() async {
    final state = ref.read(addExpenseControllerProvider);
    final choice = await showCategoryPicker(
      context,
      initialCategory: state.category,
      initialSubcategory: state.subcategory,
    );
    if (choice != null) {
      _controller.selectSubcategory(choice.category, choice.subcategory);
    }
  }

  Future<void> _pickDate() async {
    final day = await showDateSheet(
      context,
      ref.read(addExpenseControllerProvider).day,
    );
    if (day != null) _controller.selectDay(day);
  }

  Future<void> _editNote() async {
    final note = await showNoteSheet(
      context,
      ref.read(addExpenseControllerProvider).note,
    );
    if (note != null) _controller.setNote(note);
  }

  Future<void> _onPrimary() async {
    final state = ref.read(addExpenseControllerProvider);
    switch (state.step) {
      case AddExpenseStep.enterAmount:
        _rejectAmount();
      case AddExpenseStep.chooseCategory:
        await _pickCategory();
      case AddExpenseStep.ready:
        await _save(state);
    }
  }

  Future<void> _save(AddExpenseState state) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final saved = await _controller.save();
      if (!saved || !mounted) return;
      Haptics.medium();
      context.pop();
      messenger.showSnackBar(
        appToast(
          '${formatMad(state.amountCents!)} · ${state.subcategory!.name} saved',
          kind: ToastKind.success,
        ),
      );
    } catch (e, stack) {
      debugPrint('Failed to save expense: $e\n$stack');
      Haptics.heavy();
      messenger.showSnackBar(
        appToast(
          'Could not save the expense. Try again.',
          kind: ToastKind.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addExpenseControllerProvider);
    final cents = state.amountCents;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Keys shrink on short phones so everything stays on one screen.
            final keyHeight = (constraints.maxHeight * 0.075).clamp(46.0, 64.0);

            return Column(
              children: [
                _TopBar(onClose: () => context.pop()),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AmountDisplay(
                        text: state.amountText,
                        shakeTrigger: _shake,
                      ),
                      const SizedBox(height: 28),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: CategoryField(
                          category: state.category,
                          subcategory: state.subcategory,
                          highlight:
                              state.step == AddExpenseStep.chooseCategory,
                          onTap: _pickCategory,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          DetailPill(
                            icon: Icons.calendar_today_rounded,
                            label: formatDayLabel(state.day),
                            semanticLabel:
                                'Date: ${formatDayLabel(state.day)}. Change',
                            onTap: _pickDate,
                          ),
                          DetailPill(
                            icon: Icons.notes_rounded,
                            label: state.note.isEmpty ? 'Add note' : state.note,
                            isSet: state.note.isNotEmpty,
                            semanticLabel: state.note.isEmpty
                                ? 'Add note'
                                : 'Note: ${state.note}. Edit',
                            onTap: _editNote,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: AmountKeypad(
                    keyHeight: keyHeight,
                    onKey: _onKey,
                    onClear: _controller.clearAmount,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: SaveButton(
                    step: state.step,
                    isSaving: state.isSaving,
                    amountLabel: cents == null ? '' : formatMad(cents),
                    onPressed: _onPrimary,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            'New Expense',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Positioned(
            left: 12,
            child: Pressable(
              onTap: onClose,
              semanticLabel: 'Close',
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
