import 'package:database/database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../../shared/category_visuals.dart';
import '../../../shared/formatters.dart';

/// One expense row. Swipe left to delete (the screen offers Undo); tap for
/// details.
class ExpenseTile extends StatelessWidget {
  const ExpenseTile({
    super.key,
    required this.details,
    required this.onTap,
    required this.onDelete,
  });

  final ExpenseDetails details;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final expense = details.expense;
    final note = expense.note;
    final time = DateFormat.Hm().format(expense.date);

    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.35},
      onDismissed: (_) => onDelete(),
      background: Container(
        color: const Color(0xFFFF3B30),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white, size: 22),
            SizedBox(width: 6),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: Material(
        color: AppColors.surface,
        child: InkWell(
          onTap: onTap,
          child: Semantics(
            label:
                '${details.subcategory.name}, ${formatMad(expense.amountCents)}'
                '${note == null ? '' : ', $note'}, $time',
            hint: 'Swipe left to delete',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  CategoryAvatar(
                    name: details.category.name,
                    colorHex: details.category.color,
                    size: 42,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          details.subcategory.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${note ?? details.category.name}  ·  $time',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    formatAmount(expense.amountCents),
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A day's section: header (day label + total) and a rounded card of rows.
class DaySection extends StatelessWidget {
  const DaySection({
    super.key,
    required this.label,
    required this.totalCents,
    required this.children,
  });

  final String label;
  final int totalCents;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                formatMad(totalCents),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: ColoredBox(
            color: AppColors.surface,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 0.5,
                      thickness: 0.5,
                      indent: 68,
                      color: AppColors.border,
                    ),
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
