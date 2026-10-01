import 'package:flutter/material.dart';

import '../app_assets.dart';

/// The QuikExpense logomark (bundled in `ui_kit`'s own `assets/images/`).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.imageLogo,
      package: 'ui_kit',
      width: size,
      height: size,
    );
  }
}
