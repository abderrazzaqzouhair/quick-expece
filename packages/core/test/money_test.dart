import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money.parseCents', () {
    test('parses whole and decimal amounts', () {
      expect(Money.parseCents('12'), 1200);
      expect(Money.parseCents('12.5'), 1250);
      expect(Money.parseCents('12,05'), 1205);
      expect(Money.parseCents('12.'), 1200);
      expect(Money.parseCents(' 0.99 '), 99);
    });

    test('rejects empty or invalid input', () {
      expect(Money.parseCents(''), isNull);
      expect(Money.parseCents('.5'), isNull);
      expect(Money.parseCents('1.234'), isNull);
      expect(Money.parseCents('abc'), isNull);
      expect(Money.parseCents('-3'), isNull);
    });
  });

  test('Money.formatCents', () {
    expect(Money.formatCents(1250), '12.50');
    expect(Money.formatCents(5), '0.05');
    expect(Money.formatCents(100000), '1000.00');
  });
}
