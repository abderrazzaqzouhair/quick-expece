import 'package:flutter_test/flutter_test.dart';
import 'package:quik_expense_mobile/features/add_expense/logic/amount_entry.dart';

String type(List<AmountKey> keys) {
  var text = '';
  for (final key in keys) {
    text = AmountEntry.press(text, key) ?? text;
  }
  return text;
}

void main() {
  const k = AmountKey.values;

  group('AmountEntry.press', () {
    test('builds integers and decimals', () {
      expect(type([k[4], k[2]]), '42');
      expect(type([k[4], k[2], AmountKey.decimal, k[5]]), '42.5');
      expect(type([AmountKey.decimal, k[9], k[9]]), '0.99');
    });

    test('rejects a third decimal and a second point', () {
      expect(AmountEntry.press('1.25', AmountKey.d3), isNull);
      expect(AmountEntry.press('1.2', AmountKey.decimal), isNull);
    });

    test('caps integer digits at the database limit', () {
      expect(AmountEntry.press('99999999', AmountKey.d1), isNull);
      expect(AmountEntry.press('99999999', AmountKey.decimal), '99999999.');
    });

    test('no leading zeros', () {
      expect(AmountEntry.press('0', AmountKey.d0), isNull);
      expect(AmountEntry.press('0', AmountKey.d7), '7');
    });

    test('backspace', () {
      expect(AmountEntry.press('42.5', AmountKey.backspace), '42.');
      expect(AmountEntry.press('4', AmountKey.backspace), '');
      expect(AmountEntry.press('', AmountKey.backspace), isNull);
    });
  });

  test('AmountEntry.display groups thousands and keeps decimals', () {
    expect(AmountEntry.display(''), '0');
    expect(AmountEntry.display('1250'), '1,250');
    expect(AmountEntry.display('1250.'), '1,250.');
    expect(AmountEntry.display('1250.5'), '1,250.5');
    expect(AmountEntry.display('99999999.99'), '99,999,999.99');
  });
}
