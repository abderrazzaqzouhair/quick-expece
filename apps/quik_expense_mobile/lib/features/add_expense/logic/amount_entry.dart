import 'package:intl/intl.dart';

/// Keys on the add-expense number pad.
enum AmountKey {
  d0('0'),
  d1('1'),
  d2('2'),
  d3('3'),
  d4('4'),
  d5('5'),
  d6('6'),
  d7('7'),
  d8('8'),
  d9('9'),
  decimal('.'),
  backspace('');

  const AmountKey(this.symbol);
  final String symbol;

  bool get isDigit => this != decimal && this != backspace;
}

/// Pure rules for typing an amount on the keypad — no widgets, fully
/// unit-tested. The raw text is what the user typed (`"1250.5"`); it is
/// parsed to cents with `Money.parseCents`.
abstract final class AmountEntry {
  static const maxIntegerDigits = 8; // 99,999,999.99 — the database limit
  static const maxDecimals = 2;

  static final _grouping = NumberFormat('#,##0', 'en_US');

  /// The text after pressing [key], or `null` if the key is rejected (too
  /// many digits, a second decimal point…) so the UI can give feedback.
  static String? press(String text, AmountKey key) {
    if (key == AmountKey.backspace) {
      return text.isEmpty ? null : text.substring(0, text.length - 1);
    }

    final dot = text.indexOf('.');

    if (key == AmountKey.decimal) {
      if (dot != -1) return null;
      return text.isEmpty ? '0.' : '$text.';
    }

    // Digit.
    if (dot != -1) {
      return text.length - dot - 1 >= maxDecimals ? null : text + key.symbol;
    }
    if (text == '0') return key == AmountKey.d0 ? null : key.symbol;
    if (text.length >= maxIntegerDigits) return null;
    return text + key.symbol;
  }

  /// Display form with thousands separators, keeping what was typed after
  /// the decimal point: `"1250.5"` → `"1,250.5"`. Empty → `"0"`.
  static String display(String text) {
    if (text.isEmpty) return '0';
    final dot = text.indexOf('.');
    final integer = dot == -1 ? text : text.substring(0, dot);
    final grouped = _grouping.format(
      int.parse(integer.isEmpty ? '0' : integer),
    );
    return dot == -1 ? grouped : '$grouped${text.substring(dot)}';
  }
}
