import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Filled text field with a subtle inner border and a focus-aware icon badge
/// (tints to brand color on focus) — the app's standard form input. Wraps
/// [TextFormField] so it composes with a parent [Form] for validation.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hintText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.validator,
    this.autovalidateMode,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofillHints,
  });

  final String? label;
  final String? hintText;
  final String? helperText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final AutovalidateMode? autovalidateMode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  static const _radius = 16.0;
  static const _animationDuration = Duration(milliseconds: 200);

  late final FocusNode _focusNode;
  late final bool _ownsFocusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_isFocused == _focusNode.hasFocus) return;
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    final field = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        onChanged: widget.onChanged,
        validator: widget.validator,
        autovalidateMode: widget.autovalidateMode,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onFieldSubmitted,
        autofillHints: widget.autofillHints,
        style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: const TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
          helperText: widget.helperText,
          helperStyle: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
          helperMaxLines: 2,
          prefixIcon: widget.prefixIcon != null
              ? Center(
                  child: AnimatedContainer(
                    duration: _animationDuration,
                    curve: Curves.easeOut,
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(left: 12, right: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(
                        alpha: _isFocused ? 0.16 : 0.09,
                      ),
                    ),
                    child: Icon(
                      widget.prefixIcon,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                )
              : null,
          // Tight, not just a minimum — an unbounded max let `Center` above
          // expand to fill the whole field, blowing the badge up to fill
          // the input and pushing the hint text out entirely.
          prefixIconConstraints: const BoxConstraints.tightFor(
            width: 56,
            height: 40,
          ),
          suffixIcon: widget.suffixIcon,
          filled: true,
          fillColor: AppColors.inputFill,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          border: _border(AppColors.border),
          enabledBorder: _border(AppColors.border),
          focusedBorder: _border(AppColors.primary, width: 1.6),
          errorBorder: _border(AppColors.error, width: 1.2),
          focusedErrorBorder: _border(AppColors.error, width: 1.6),
          errorStyle: const TextStyle(fontSize: 12.5, color: AppColors.error),
        ),
      ),
    );

    if (widget.label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label!,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        field,
      ],
    );
  }
}
