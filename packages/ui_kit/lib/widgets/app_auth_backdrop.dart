import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Soft ambient brand-color blobs behind auth-screen content — gives the
/// page some depth instead of a flat, empty canvas. Purely decorative, so
/// it's wrapped in `IgnorePointer` and excluded from the semantics tree.
class AppAuthBackdrop extends StatelessWidget {
  const AppAuthBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: Stack(
                children: [
                  Positioned(
                    top: -90,
                    right: -70,
                    child: _blob(
                      240,
                      AppColors.primary.withValues(alpha: 0.14),
                    ),
                  ),
                  Positioned(
                    top: 160,
                    left: -110,
                    child: _blob(
                      220,
                      AppColors.primaryLight.withValues(alpha: 0.10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _blob(double size, Color color) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
