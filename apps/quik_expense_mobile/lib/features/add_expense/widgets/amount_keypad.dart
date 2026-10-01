import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../../shared/widgets/pressable.dart';
import '../logic/amount_entry.dart';
import '../../../shared/haptics.dart';

/// Built-in number pad (Apple Cash style) — replaces the system keyboard so
/// nothing on the screen gets covered. Selection haptic on every key;
/// long-press ⌫ clears.
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({
    super.key,
    required this.onKey,
    required this.onClear,
    this.keyHeight = 60,
  });

  final ValueChanged<AmountKey> onKey;
  final VoidCallback onClear;
  final double keyHeight;

  static const _rows = [
    [AmountKey.d1, AmountKey.d2, AmountKey.d3],
    [AmountKey.d4, AmountKey.d5, AmountKey.d6],
    [AmountKey.d7, AmountKey.d8, AmountKey.d9],
    [AmountKey.decimal, AmountKey.d0, AmountKey.backspace],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in _rows)
          Row(
            children: [
              for (final key in row)
                Expanded(
                  child: _Key(
                    key: ValueKey('amount-key-${key.name}'),
                    amountKey: key,
                    height: keyHeight,
                    onTap: () {
                      Haptics.selection();
                      onKey(key);
                    },
                    onLongPress: key == AmountKey.backspace
                        ? () {
                            Haptics.medium();
                            onClear();
                          }
                        : null,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _Key extends StatefulWidget {
  const _Key({
    super.key,
    required this.amountKey,
    required this.height,
    required this.onTap,
    this.onLongPress,
  });

  final AmountKey amountKey;
  final double height;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> {
  bool _down = false;

  String get _label => switch (widget.amountKey) {
    AmountKey.backspace => 'Delete',
    AmountKey.decimal => 'Decimal point',
    final k => k.symbol,
  };

  @override
  Widget build(BuildContext context) {
    final key = widget.amountKey;

    final Widget glyph = switch (key) {
      AmountKey.backspace => const Icon(
        Icons.backspace_outlined,
        size: 24,
        color: AppColors.textPrimary,
      ),
      _ => Text(
        key.symbol,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
    };

    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: Pressable(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        pressedScale: 0.92,
        semanticLabel: _label,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: AnimatedContainer(
            duration: Duration(milliseconds: _down ? 60 : 240),
            height: widget.height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _down
                  ? Colors.black.withValues(alpha: 0.07)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: ExcludeSemantics(child: glyph),
          ),
        ),
      ),
    );
  }
}
