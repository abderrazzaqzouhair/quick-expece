import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../config/router/app_routes.dart';

/// UI-only — consumes the `auth` package's providers/controllers for logic
/// once sign-up is implemented. Field validation is real (client-side,
/// mirroring the backend's `RegisterRequest` rules); the submit/social
/// handlers below are still no-op placeholders.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    _formKey.currentState?.validate();
  }

  void _goToSignIn(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.signIn);
    }
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
                  const AppBrandLockup(),
                  const SizedBox(height: 28),
                  Text(
                    'Create your account',
                    style: AppTextStyles.displayHeading,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start tracking your expenses in minutes.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  AppTextField(
                    label: 'Full name',
                    hintText: 'Jane Doe',
                    prefixIcon: Icons.person_outline,
                    keyboardType: TextInputType.name,
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    validator: (value) =>
                        Validators.minLength(value, 2, label: 'Name'),
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_emailFocusNode),
                  ),
                  // Tighter gap — "Full name" and "Email" are one logical
                  // group (who you are).
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Email',
                    hintText: 'you@company.com',
                    prefixIcon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: Validators.email,
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_passwordFocusNode),
                  ),
                  // Wider gap — marks the switch from "who you are" to "how
                  // you'll sign in", instead of every field reading as one
                  // undifferentiated stack.
                  const SizedBox(height: 25),
                  AppPasswordField(
                    label: 'Password',
                    hintText: 'Create a password',
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    // Matches the backend's `Password::min(8)` rule in
                    // RegisterRequest.
                    validator: (value) =>
                        Validators.minLength(value, 8, label: 'Password'),
                    onFieldSubmitted: (_) => FocusScope.of(
                      context,
                    ).requestFocus(_confirmPasswordFocusNode),
                  ),
                  // A touch more room than the other gaps — the helper text
                  // under Password already sits close beneath it, so this gap
                  // needs to separate two lines of text, not one.
                  const SizedBox(height: 24),
                  AppPasswordField(
                    label: 'Confirm password',
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
                    label: 'Create account',
                    trailingIcon: Icons.arrow_forward,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _goToSignIn(context),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Sign in',
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
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
