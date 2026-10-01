import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../../shared/widgets/pressable.dart';
import '../add_expense_controller.dart';

/// Primary action that also guides: until the form is complete its label
/// says what's missing (and the screen reacts to the tap — shake the
/// amount, open the category sheet). Ready: brand gradient + the amount.
class SaveButton extends StatelessWidget {
  const SaveButton({
    super.key,
    required this.step,
    required this.amountLabel,
    required this.isSaving,
    required this.onPressed,
  });

  final AddExpenseStep step;

  /// e.g. `42.50 MAD`, shown when ready.
  final String amountLabel;
  final bool isSaving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ready = step == AddExpenseStep.ready;
    final label = switch (step) {
      AddExpenseStep.enterAmount => 'Enter an amount',
      AddExpenseStep.chooseCategory => 'Choose a category',
      AddExpenseStep.ready => 'Save  ·  $amountLabel',
    };

    return Pressable(
      onTap: isSaving ? null : onPressed,
      pressedScale: 0.97,
      semanticLabel: ready ? 'Save expense, $amountLabel' : label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: ready ? null : Colors.black.withValues(alpha: 0.06),
          gradient: ready
              ? LinearGradient(
                  colors: [AppColors.primaryLight, AppColors.primary],
                )
              : null,
          boxShadow: ready
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: isSaving
              ? const SizedBox(
                  key: ValueKey('saving'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.onPrimary,
                  ),
                )
              : Text(
                  label,
                  key: ValueKey(label),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: ready
                        ? AppColors.onPrimary
                        : AppColors.textSecondary,
                  ),
                ),
        ),
      ),
    );
  }
}
