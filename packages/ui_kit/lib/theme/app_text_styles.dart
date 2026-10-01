import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Text theme built on Google Fonts.
///
/// Two-font system: Calistoga for headlines (adds warmth/character — a
/// fintech-appropriate "boutique" display face), Inter for everything else
/// (body copy, labels, buttons) since it reads cleanly at small sizes.
abstract final class AppTextStyles {
  static TextTheme get textTheme => GoogleFonts.interTextTheme().copyWith(
    headlineSmall: GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    bodyMedium: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
    bodySmall: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
  );

  /// Screen-level headline (e.g. "Welcome back") — Calistoga, not Inter.
  static TextStyle get displayHeading => GoogleFonts.calistoga(
    fontSize: 32,
    height: 1.15,
    color: AppColors.textPrimary,
  );
}
