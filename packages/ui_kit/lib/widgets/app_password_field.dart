import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_text_field.dart';

/// [AppTextField] with a built-in show/hide toggle — the app's standard
/// password input.
class AppPasswordField extends StatefulWidget {
  const AppPasswordField({
    super.key,
    this.label,
    this.hintText,
    this.helperText,
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
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final AutovalidateMode? autovalidateMode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: widget.label,
      hintText: widget.hintText,
      helperText: widget.helperText,
      controller: widget.controller,
      focusNode: widget.focusNode,
      onChanged: widget.onChanged,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      autofillHints: widget.autofillHints,
      obscureText: _obscure,
      prefixIcon: Icons.lock_outline,
      suffixIcon: IconButton(
        icon: Icon(
          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 20,
          color: AppColors.textSecondary,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
  }
}
