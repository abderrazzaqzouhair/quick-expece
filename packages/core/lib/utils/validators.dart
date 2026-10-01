/// Reusable form-field validators. Framework-agnostic (no `BuildContext`,
/// no widgets) so every feature's forms share one implementation instead of
/// re-declaring the same regex/rules per screen.
abstract final class Validators {
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Non-empty check (after trimming).
  static String? required(String? value, [String label = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    return null;
  }

  /// Basic email format check.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter your email.';
    if (!_emailPattern.hasMatch(value.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  /// Non-empty + minimum length — e.g. for passwords.
  static String? minLength(
    String? value,
    int length, {
    String label = 'This field',
  }) {
    if (value == null || value.isEmpty) return '$label is required.';
    if (value.length < length) {
      return '$label must be at least $length characters.';
    }
    return null;
  }

  /// Value must equal [other] — for confirm-password fields. [other] is a
  /// getter (not the raw text) so it re-reads the latest value on every
  /// validation pass rather than capturing it once.
  static String? matches(
    String? value,
    String Function() other, {
    String message = 'Values do not match.',
  }) {
    if (value == null || value.isEmpty) return message;
    if (value != other()) return message;
    return null;
  }
}
