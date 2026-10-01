import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../config/router/app_routes.dart';

/// Step 1 of 3 — UI-only, no backend call yet (the Laravel API has no
/// password-reset endpoint exposed). "Send code" just validates the email
/// and moves to [AppRoutes.verifyResetCode], passing it along as a query
/// param so the flow stays deep-link-able.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    final email = Uri.encodeQueryComponent(_emailController.text.trim());
    context.push('${AppRoutes.verifyResetCode}?email=$email');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
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
                    onPressed: () => context.pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(height: 16),
                  Text('Forgot password?', style: AppTextStyles.displayHeading),
                  const SizedBox(height: 8),
                  Text(
                    "Enter the email linked to your account and we'll send "
                    'you a 6-digit reset code.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  AppTextField(
                    label: 'Email',
                    hintText: 'you@company.com',
                    prefixIcon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    validator: Validators.email,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 32),
                  AppPrimaryButton(
                    label: 'Send code',
                    trailingIcon: Icons.arrow_forward,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton(
                      onPressed: () => context.pop(),
                      child: Text(
                        'Back to sign in',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
