import 'package:database/database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../../shared/category_visuals.dart';
import '../../../shared/formatters.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/pressable.dart';

/// Read-only expense details with a Delete action. Returns `true` when the
/// user chose Delete.
Future<bool?> showExpenseDetailSheet(
  BuildContext context,
  ExpenseDetails details,
) {
  return showAppSheet<bool>(
    context,
    builder: (_) => _ExpenseDetailSheet(details: details),
  );
}

class _ExpenseDetailSheet extends StatelessWidget {
  const _ExpenseDetailSheet({required this.details});

  final ExpenseDetails details;

  @override
  Widget build(BuildContext context) {
    final expense = details.expense;
    final color = CategoryVisuals.colorFor(details.category.color);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSheetHeader(
          title: 'Expense',
          trailing: SheetTextButton(
            label: 'Done',
            isPrimary: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(height: 4),
        CategoryAvatar(
          name: details.category.name,
          colorHex: details.category.color,
          size: 64,
        ),
        const SizedBox(height: 14),
        Text(
          formatMad(expense.amountCents),
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
            color: AppColors.textPrimary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          details.subcategory.name,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GroupedCard(
            children: [
              _InfoRow(label: 'Category', value: details.category.name),
              _InfoRow(
                label: 'Date',
                value: DateFormat('EEEE d MMMM yyyy').format(expense.date),
              ),
              _InfoRow(
                label: 'Time',
                value: DateFormat.Hm().format(expense.date),
              ),
              if (expense.note != null)
                _InfoRow(label: 'Note', value: expense.note!, multiline: true),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Pressable(
            onTap: () => Navigator.of(context).pop(true),
            pressedScale: 0.97,
            semanticLabel: 'Delete expense',
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Delete Expense',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF3B30),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.multiline = false,
  });

  final String label;
  final String value;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: multiline ? TextAlign.start : TextAlign.end,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
