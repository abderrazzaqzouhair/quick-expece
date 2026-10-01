import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'selectable_chip.dart';

/// Today / Yesterday quick picks, plus a calendar chip for any other past
/// day. Future days aren't allowed (same rule as the backend).
class DaySelector extends StatelessWidget {
  const DaySelector({super.key, required this.day, required this.onChanged});

  /// Date-only (midnight).
  final DateTime day;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final isOther = day != today && day != yesterday;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SelectableChip(
          label: 'Today',
          selected: day == today,
          onTap: () => onChanged(today),
        ),
        SelectableChip(
          label: 'Yesterday',
          selected: day == yesterday,
          onTap: () => onChanged(yesterday),
        ),
        SelectableChip(
          label: isOther
              ? DateFormat('EEE d MMM yyyy').format(day)
              : 'Other day',
          icon: Icons.calendar_today_rounded,
          selected: isOther,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: day,
              firstDate: DateTime(2000),
              lastDate: today,
            );
            if (picked != null) onChanged(picked);
          },
        ),
      ],
    );
  }
}
