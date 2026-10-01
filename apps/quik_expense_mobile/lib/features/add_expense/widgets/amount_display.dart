import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

import '../logic/amount_entry.dart';

/// The hero amount: large tabular figures with the currency beside them.
/// Shrinks to fit long numbers and shakes horizontally whenever
/// [shakeTrigger] changes (rejected key, or Save pressed without an amount).
class AmountDisplay extends StatefulWidget {
  const AmountDisplay({
    super.key,
    required this.text,
    required this.shakeTrigger,
    this.currency = 'MAD',
  });

  /// Raw keypad text (see [AmountEntry]).
  final String text;
  final int shakeTrigger;
  final String currency;

  @override
  State<AmountDisplay> createState() => _AmountDisplayState();
}

class _AmountDisplayState extends State<AmountDisplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  @override
  void didUpdateWidget(AmountDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shakeTrigger != oldWidget.shakeTrigger &&
        !MediaQuery.disableAnimationsOf(context)) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = widget.text.isEmpty;
    final display = AmountEntry.display(widget.text);

    const figures = [FontFeature.tabularFigures()];

    return Semantics(
      label: 'Amount $display ${widget.currency}',
      liveRegion: true,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _shake,
        builder: (context, child) {
          // Damped sine: 3 swings that settle.
          final t = _shake.value;
          final dx = math.sin(t * math.pi * 6) * 10 * (1 - t);
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 150),
                  style: TextStyle(
                    fontSize: 72,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -2.5,
                    fontFeatures: figures,
                    color: isEmpty
                        ? AppColors.textSecondary.withValues(alpha: 0.35)
                        : AppColors.textPrimary,
                  ),
                  child: Text(display),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.currency,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
