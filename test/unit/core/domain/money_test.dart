import 'package:build_ledger/core/domain/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money Value Object', () {
    test('creates Money from minor units', () {
      final m = Money.fromMinor(2500000); // Rs 25,000.00
      expect(m.minorUnits, equals(2500000));
      expect(m.toDoubleMajor(), equals(25000.0));
      expect(m.isPositive, isTrue);
      expect(m.isZero, isFalse);
      expect(m.isNegative, isFalse);
    });

    test('creates Money from parse decimal strings', () {
      expect(Money.parse('18500').minorUnits, equals(1850000));
      expect(Money.parse('18500.5').minorUnits, equals(1850050));
      expect(Money.parse('18500.75').minorUnits, equals(1850075));
      expect(Money.parse('25,000.00').minorUnits, equals(2500000));
      expect(Money.parse('0').minorUnits, equals(0));
      expect(Money.parse('-500.25').minorUnits, equals(-50025));
    });

    test('deterministic arithmetic operations', () {
      final a = Money.fromMinor(100000); // Rs 1,000.00
      final b = Money.fromMinor(45050);  // Rs 450.50

      final sum = a + b;
      expect(sum.minorUnits, equals(145050));

      final diff = a - b;
      expect(diff.minorUnits, equals(54950));

      final multiplied = b * 3;
      expect(multiplied.minorUnits, equals(135150));

      final divided = a.divideByFactor(3);
      expect(divided.minorUnits, equals(33333)); // 100000 / 3 = 33333.333 -> 33333
    });

    test('fixed-point labour day scaling (days_x100)', () {
      final dailyRate = Money.fromMinor(250000); // Rs 2,500/day
      // 1.5 days -> factorX100 = 150
      final wage = dailyRate.multiplyByFixedPoint100(150);
      expect(wage.minorUnits, equals(375000)); // Rs 3,750.00 exactly

      // 0.75 days -> factorX100 = 75
      final halfDayWage = dailyRate.multiplyByFixedPoint100(75);
      expect(halfDayWage.minorUnits, equals(187500)); // Rs 1,875.00
    });

    test('comparisons and equality', () {
      final a = Money.fromMinor(5000);
      final b = Money.fromMinor(5000);
      final c = Money.fromMinor(7000);

      expect(a == b, isTrue);
      expect(a == c, isFalse);
      expect(c > a, isTrue);
      expect(a < c, isTrue);
      expect(a <= b, isTrue);
      expect(a >= b, isTrue);
    });
  });
}
