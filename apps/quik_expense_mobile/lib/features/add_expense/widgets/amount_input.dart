import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui_kit/ui_kit.dart';

/// Large, centered amount field — the first thing the user types, so it's
/// autofocused with the decimal keypad. Accepts up to 8 digits and 2
/// decimals (`.` or `,`), matching the database limit.
class AmountInput extends StatelessWidget {
  const AmountInput({
    super.key,
    required this.controller,
    required this.onChanged,
    this.currency = 'MAD',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String currency;

  static final _pattern = RegExp(r'^\d{0,8}([.,]\d{0,2})?$');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Text(
            'Amount',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              IntrinsicWidth(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    TextInputFormatter.withFunction(
                      (oldValue, newValue) => _pattern.hasMatch(newValue.text)
                          ? newValue
                          : oldValue,
                    ),
                  ],
                  cursorColor: AppColors.primary,
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -1,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      color: AppColors.border,
                      letterSpacing: -1,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                currency,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
