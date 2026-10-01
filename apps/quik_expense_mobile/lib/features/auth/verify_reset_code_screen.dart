import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../config/router/app_routes.dart';

/// Step 2 of 3 — UI-only. [email] arrives via the `email` query param from
/// [ForgotPasswordScreen] so this screen stays deep-link-able on its own.
class VerifyResetCodeScreen extends StatefulWidget {
  const VerifyResetCodeScreen({super.key, required this.email});

  final String email;

  static const codeLength = 6;
  static const resendCooldown = Duration(seconds: 30);

  @override
  State<VerifyResetCodeScreen> createState() => _VerifyResetCodeScreenState();
}

class _VerifyResetCodeScreenState extends State<VerifyResetCodeScreen> {
  String _code = '';
  String? _errorText;
  Timer? _resendTimer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _startResendCooldown();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(
      () => _secondsRemaining = VerifyResetCodeScreen.resendCooldown.inSeconds,
    );
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  void _handleCodeChanged(String value) {
    setState(() {
      _code = value;
      if (_errorText != null) _errorText = null;
    });
  }

  void _submit() {
    if (_code.length != VerifyResetCodeScreen.codeLength) {
      setState(() => _errorText = 'Enter the full 6-digit code.');
      return;
    }
    final email = Uri.encodeQueryComponent(widget.email);
    final code = Uri.encodeQueryComponent(_code);
    context.push('${AppRoutes.resetPassword}?email=$email&code=$code');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final canResend = _secondsRemaining == 0;

    return Scaffold(
      body: AppAuthBackdrop(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
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
                Text('Enter the code', style: AppTextStyles.displayHeading),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      const TextSpan(text: 'We sent a 6-digit code to '),
                      TextSpan(
                        text: widget.email,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                AppOtpInput(
                  length: VerifyResetCodeScreen.codeLength,
                  onChanged: _handleCodeChanged,
                  onCompleted: (_) => _submit(),
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorText!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.error,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                AppPrimaryButton(
                  label: 'Verify',
                  trailingIcon: Icons.arrow_forward,
                  onPressed: _submit,
                ),
                const SizedBox(height: 24),
                Center(
                  child: canResend
                      ? TextButton(
                          onPressed: _startResendCooldown,
                          child: Text(
                            'Resend code',
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : Text(
                          'Resend code in 0:${_secondsRemaining.toString().padLeft(2, '0')}',
                          style: textTheme.bodySmall,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
