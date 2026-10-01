/// Money helpers. Amounts are handled as integer cents everywhere (the local
/// database stores `amount_cents`) to avoid floating-point rounding.
abstract final class Money {
  /// Largest amount accepted — mirrors the backend's `max:99999999.99`.
  static const int maxCents = 9999999999;

  static final RegExp _amountPattern = RegExp(r'^(\d+)(?:[.,](\d{0,2}))?$');

  /// Parses user input like `12`, `12.5`, `12,50` or `12.` into cents.
  /// Returns `null` for empty/invalid input or more than 2 decimals.
  static int? parseCents(String input) {
    final match = _amountPattern.firstMatch(input.trim());
    if (match == null) return null;
    final units = int.parse(match.group(1)!);
    final decimals = (match.group(2) ?? '').padRight(2, '0');
    return units * 100 + int.parse(decimals);
  }

  /// `1250` → `12.50` (no grouping, no currency — format for display in the
  /// UI layer).
  static String formatCents(int cents) {
    final units = cents ~/ 100;
    final rest = (cents % 100).toString().padLeft(2, '0');
    return '$units.$rest';
  }
}
