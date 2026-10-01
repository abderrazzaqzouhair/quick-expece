import 'package:flutter/cupertino.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/haptics.dart';

/// iOS date wheel with Today / Yesterday shortcuts. Future days can't be
/// picked (same rule as the backend). Returns the picked day, or `null`.
Future<DateTime?> showDateSheet(BuildContext context, DateTime initial) {
  return showAppSheet<DateTime>(
    context,
    builder: (_) => _DateSheet(initial: initial),
  );
}

class _DateSheet extends StatefulWidget {
  const _DateSheet({required this.initial});

  final DateTime initial;

  @override
  State<_DateSheet> createState() => _DateSheetState();
}

class _DateSheetState extends State<_DateSheet> {
  late DateTime _day = widget.initial;
  // Rebuilds the wheel when a shortcut jumps it to another day.
  int _wheelVersion = 0;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void _jumpTo(DateTime day) {
    Haptics.selection();
    setState(() {
      _day = day;
      _wheelVersion++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = _today;
    final yesterday = today.subtract(const Duration(days: 1));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSheetHeader(
          title: 'Date',
          leading: SheetTextButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
          ),
          trailing: SheetTextButton(
            label: 'Done',
            isPrimary: true,
            onPressed: () => Navigator.of(context).pop(_day),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: _Shortcut(
                  label: 'Today',
                  selected: _day == today,
                  onTap: () => _jumpTo(today),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Shortcut(
                  label: 'Yesterday',
                  selected: _day == yesterday,
                  onTap: () => _jumpTo(yesterday),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 216,
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: CupertinoTheme(
            data: const CupertinoThemeData(
              textTheme: CupertinoTextThemeData(
                dateTimePickerTextStyle: TextStyle(
                  fontSize: 21,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            child: CupertinoDatePicker(
              key: ValueKey(_wheelVersion),
              mode: CupertinoDatePickerMode.date,
              initialDateTime: _day,
              minimumDate: DateTime(2000),
              maximumDate: today,
              dateOrder: DatePickerDateOrder.dmy,
              onDateTimeChanged: (value) => setState(
                () => _day = DateTime(value.year, value.month, value.day),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.onPrimary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
