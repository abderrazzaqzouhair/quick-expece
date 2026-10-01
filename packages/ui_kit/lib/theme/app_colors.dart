import 'package:flutter/material.dart';

/// Brand color tokens, matched to the QuikExpense sign-in design.
///
/// `secondary` is derived from `primary` (same hue, lower lightness) rather
/// than picked independently — a one-seed tonal palette, the same idea
/// Material 3's `ColorScheme.fromSeed` uses internally. That also fixes a
/// real accessibility gap: `primary` at full brightness only hits ~3.2:1
/// contrast as text on a light surface (below the 4.5:1 AA minimum); the
/// darker tone clears ~6.9:1 while still reading as "the same brand color".
abstract final class AppColors {
  static const Color primary = Color(0xFFF2600C);

  static Color get secondary =>
      HSLColor.fromColor(primary).withLightness(0.5).toColor();

  /// Lighter tint of `primary` (same hue, higher lightness) — the warm end
  /// of the gradient on [AppPrimaryButton]. Same derivation idea as
  /// `secondary`, just lightened instead of darkened.
  static Color get primaryLight =>
      HSLColor.fromColor(primary).withLightness(0.6).toColor();

  static const Color background = Color(0xFFF6F7F8);
  static const Color surface = Color(0xFFFFFFFF);

  // White, not a gray fill — inputs read as cards floating on `background`,
  // with `border` + the widget's own shadow doing the definition. A gray
  // fill this close in lightness to `background` (the old F0F1F3) made
  // fields blend into the page instead of looking distinctly tappable.
  static const Color inputFill = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE3E5E9);
  static const Color error = Color(0xFFBA1A1A);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1B1B1B);
  static const Color textSecondary = Color(0xFF6B6B6B);
}
