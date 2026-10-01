import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../config/router/app_routes.dart';

/// Step 3 of 3 — UI-only. [email]/[code] arrive via query params from
/// [VerifyResetCodeScreen]; neither is sent anywhere yet since there's no
/// backend endpoint for this flow. On "successful" validation this is a
/// terminal step, so it replaces history (`context.go`) back to sign-in
/// rather than pushing — there's nothing to "go back" to in this flow once
/// it's done.
///
/// Back (system gesture/button, and the in-app back arrow) also goes
/// straight to sign-in rather than popping to the code-entry screen — once
/// the user has a valid code, re-entering it isn't a step they should be
/// able to land back on.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.email, this.code});

  final String email;
  final String? code;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    context.go(AppRoutes.signIn);
  }

  void _goToSignIn() => context.go(AppRoutes.signIn);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goToSignIn();
      },
      child: Scaffold(
        body: AppAuthBackdrop(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: _goToSignIn,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(height: 16),
                    const AppBrandLockup(),
                    const SizedBox(height: 28),
                    Text(
                      'Set a new password',
                      style: AppTextStyles.displayHeading,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Choose a strong password you haven't used before.",
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    AppPasswordField(
                      label: 'New password',
                      hintText: 'Create a password',
                      helperText: 'At least 8 characters.',
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: (value) =>
                          Validators.minLength(value, 8, label: 'Password'),
                      onFieldSubmitted: (_) => FocusScope.of(
                        context,
                      ).requestFocus(_confirmPasswordFocusNode),
                    ),
                    const SizedBox(height: 24),
                    AppPasswordField(
                      label: 'Confirm new password',
                      hintText: 'Re-enter your password',
                      controller: _confirmPasswordController,
                      focusNode: _confirmPasswordFocusNode,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: (value) => Validators.matches(
                        value,
                        () => _passwordController.text,
                        message: 'Passwords do not match.',
                      ),
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 32),
                    AppPrimaryButton(
                      label: 'Reset password',
                      trailingIcon: Icons.arrow_forward,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
