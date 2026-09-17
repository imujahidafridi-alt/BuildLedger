import 'package:flutter/foundation.dart';

/// Immutable value object representing monetary amounts in 64-bit integer minor units (paisas/cents).
/// 1 PKR = 100 paisas.
/// Absolutely NO double floating-point numbers are permitted in financial calculations.
@immutable
class Money implements Comparable<Money> {
  /// The monetary amount stored in minor units (e.g. 1850075 for Rs 18,500.75).
  final int minorUnits;

  const Money(this.minorUnits);
  const Money._(this.minorUnits);

  /// Creates a [Money] instance directly from minor units (e.g. paisas).
  factory Money.fromMinor(int minorUnits) => Money._(minorUnits);

  /// Creates a [Money] instance from whole major units (e.g. 500 PKR = 50,000 minor units).
  factory Money.fromMajor(int majorUnits) => Money._(majorUnits * 100);

  /// Integer major units (e.g. 50000 minor units -> 500 major units).
  int get majorValue => minorUnits ~/ 100;

  /// Zero money constant.
  static const Money zero = Money._(0);

  /// Parses a decimal string (e.g. "18500", "18500.50", "25,000") into [Money].
  factory Money.parse(String input) {
    final cleaned = input.replaceAll(',', '').trim();
    if (cleaned.isEmpty) return Money.zero;

    final parts = cleaned.split('.');
    if (parts.length > 2) {
      throw FormatException('Invalid money format: $input');
    }

    final whole = int.tryParse(parts[0]) ?? 0;
    if (parts.length == 1) {
      return Money._(whole * 100);
    }

    // Decimal part: take up to 2 decimal places
    String fractionStr = parts[1];
    if (fractionStr.length > 2) {
      fractionStr = fractionStr.substring(0, 2);
    } else if (fractionStr.length == 1) {
      fractionStr = '${fractionStr}0';
    }

    final fraction = int.tryParse(fractionStr) ?? 0;
    final sign = whole < 0 || cleaned.startsWith('-') ? -1 : 1;
    final totalMinor = (whole.abs() * 100 + fraction) * sign;
    return Money._(totalMinor);
  }

  /// Helper factory from num (e.g. double or int from user input at presentation boundary).
  factory Money.fromNum(num value) {
    return Money._((value * 100).round());
  }

  /// Arithmetic addition.
  Money operator +(Money other) => Money._(minorUnits + other.minorUnits);

  /// Arithmetic subtraction.
  Money operator -(Money other) => Money._(minorUnits - other.minorUnits);

  /// Multiplies by an integer factor.
  Money operator *(int factor) => Money._(minorUnits * factor);

  /// Multiplies by a fixed-point scale factor (e.g., days_x100 where 100 = 1.0 day).
  /// Result = (minorUnits * factorX100) ~/ 100
  Money multiplyByFixedPoint100(int factorX100) {
    return Money._((minorUnits * factorX100) ~/ 100);
  }

  /// Divides by an integer factor with deterministic rounding.
  Money divideByFactor(int divisor) {
    if (divisor == 0) throw ArgumentError('Cannot divide money by zero');
    return Money._((minorUnits / divisor).round());
  }

  /// Comparison operators
  bool operator >(Money other) => minorUnits > other.minorUnits;
  bool operator <(Money other) => minorUnits < other.minorUnits;
  bool operator >=(Money other) => minorUnits >= other.minorUnits;
  bool operator <=(Money other) => minorUnits <= other.minorUnits;

  bool get isNegative => minorUnits < 0;
  bool get isZero => minorUnits == 0;
  bool get isPositive => minorUnits > 0;

  /// Returns the absolute value.
  Money abs() => Money._(minorUnits.abs());

  /// Returns major units as a double ONLY for charting / progress fraction calculations.
  /// NEVER use this for domain ledger persistence or subtraction!
  double toDoubleMajor() => minorUnits / 100.0;

  @override
  int compareTo(Money other) => minorUnits.compareTo(other.minorUnits);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Money && other.minorUnits == minorUnits;

  @override
  int get hashCode => minorUnits.hashCode;

  @override
  String toString() => 'Money($minorUnits minor units)';
}
