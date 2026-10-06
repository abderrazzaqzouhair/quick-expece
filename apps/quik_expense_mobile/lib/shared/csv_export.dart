import 'package:database/database.dart';
import 'package:intl/intl.dart';

/// Expenses as CSV, oldest first — ready to paste into Sheets or Excel.
/// Used by Settings (everything) and Statistics (one period).
String expensesCsv(Iterable<ExpenseDetails> expenses) {
  final rows = expenses.toList()
    ..sort((a, b) => a.expense.date.compareTo(b.expense.date));
  final date = DateFormat('yyyy-MM-dd');
  final time = DateFormat('HH:mm');
  final buffer = StringBuffer(
    'Date,Time,Category,Subcategory,Amount (MAD),Note\n',
  );
  for (final d in rows) {
    final e = d.expense;
    buffer.writeln(
      [
        date.format(e.date),
        time.format(e.date),
        _field(d.category.name),
        _field(d.subcategory.name),
        (e.amountCents / 100).toStringAsFixed(2),
        _field(e.note ?? ''),
      ].join(','),
    );
  }
  return buffer.toString();
}

/// Quotes a field when it contains a comma, quote or newline.
String _field(String value) {
  if (!value.contains(RegExp(r'[",\n\r]'))) return value;
  return '"${value.replaceAll('"', '""')}"';
}
