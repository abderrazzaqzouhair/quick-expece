import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_logo.dart';

/// Logo + wordmark, reused on splash/auth screens.
class AppBrandLockup extends StatelessWidget {
  const AppBrandLockup({super.key, this.logoSize = 56});

  final double logoSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppLogo(size: logoSize),
        const SizedBox(height: 12),
        Text(
          'QUIKEXPENSE',
          style: TextStyle(
            // `secondary`, not `primary` — primary-orange text on this
            // background only hits ~3.2:1 contrast, below the 4.5:1 AA
            // minimum for text this size.
            color: AppColors.secondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
