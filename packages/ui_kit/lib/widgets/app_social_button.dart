import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_assets.dart';
import '../theme/app_colors.dart';

enum SocialProvider {
  apple(AppAssets.iconAppleLogo),
  google(AppAssets.iconGoogleLogo);

  const SocialProvider(this._assetPath);

  final String _assetPath;
}

/// Outlined "Continue with {Provider}" button — icon bundled in `ui_kit`,
/// screens only pick the [provider] and supply the label + handler.
class AppSocialButton extends StatelessWidget {
  const AppSocialButton({
    super.key,
    required this.provider,
    required this.label,
    required this.onPressed,
  });

  final SocialProvider provider;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(provider._assetPath, width: 20, height: 20),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
