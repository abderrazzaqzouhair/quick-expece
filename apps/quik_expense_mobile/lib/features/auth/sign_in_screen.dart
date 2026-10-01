import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../config/router/app_routes.dart';

/// UI-only — consumes the `auth` package's providers/controllers for logic
/// once sign-in is implemented. Field validation is real (client-side);
/// every submit/social handler below is still a no-op placeholder.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    // TODO: replace with a real call through the `auth` package once it's
    // wired. For now, set a placeholder session so the router's auth-gate
    // (which checks `TokenService.instance.accessToken`) lets navigation
    // through to Home instead of bouncing back here.
    await TokenService.instance.setSession(
      accessToken: 'mock-access-token',
      refreshToken: 'mock-refresh-token',
      userId: 'mock-user-id',
    );
    if (!mounted) return;
    context.go(AppRoutes.home);
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
                  Text('Welcome back', style: AppTextStyles.displayHeading),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to keep your expenses moving.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  AppTextField(
                    label: 'Email',
                    hintText: 'exemple@exemple.com',
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
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.forgotPassword),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Forgot?',
                          // `secondary`, not `primary` — see AppColors for why:
                          // primary-orange text fails AA contrast here.
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AppPasswordField(
                    hintText: 'Enter your password',
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    // Signing in only needs "did you type something" — length
                    // rules are a registration-time constraint (see sign-up),
                    // not something to re-validate against an existing account.
                    validator: (value) =>
                        Validators.required(value, 'Password'),
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 28),
                  AppPrimaryButton(
                    label: 'Sign in',
                    trailingIcon: Icons.arrow_forward,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 24),
                  const AppLabeledDivider(label: 'OR CONTINUE WITH'),
                  const SizedBox(height: 24),
                  AppSocialButton(
                    provider: SocialProvider.apple,
                    label: 'Continue with Apple',
                    onPressed: () {},
                  ),
                  const SizedBox(height: 12),
                  AppSocialButton(
                    provider: SocialProvider.google,
                    label: 'Continue with Google',
                    onPressed: () {},
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'New to QuikExpense? ',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push(AppRoutes.signUp),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Create an account',
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
