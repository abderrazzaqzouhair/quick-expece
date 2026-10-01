import 'package:intl/intl.dart';

final _money = NumberFormat('#,##0.00', 'en_US');

/// `125050` → `1,250.50`.
String formatAmount(int cents) => _money.format(cents / 100);

/// `125050` → `1,250.50 MAD`.
String formatMad(int cents) => '${formatAmount(cents)} MAD';

/// Date-only copy of [date].
DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// "Today", "Yesterday", or e.g. "Mon, 28 Sep" (year added when it isn't
/// this year).
String formatDayLabel(DateTime day) {
  final now = DateTime.now();
  final diff = dateOnly(now).difference(dateOnly(day)).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return DateFormat(
    day.year == now.year ? 'EEE, d MMM' : 'd MMM yyyy',
  ).format(day);
}
