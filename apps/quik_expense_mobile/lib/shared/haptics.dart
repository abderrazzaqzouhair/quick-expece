import 'package:flutter/services.dart';

/// App-wide haptics that respect the user's "Haptic feedback" setting
/// (Profile → Settings). Use these instead of calling [HapticFeedback]
/// directly.
abstract final class Haptics {
  /// Set from the saved setting at startup and whenever it changes.
  static bool enabled = true;

  static void selection() {
    if (enabled) HapticFeedback.selectionClick();
  }

  static void light() {
    if (enabled) HapticFeedback.lightImpact();
  }

  static void medium() {
    if (enabled) HapticFeedback.mediumImpact();
  }

  static void heavy() {
    if (enabled) HapticFeedback.heavyImpact();
  }
}
