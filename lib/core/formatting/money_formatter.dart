import 'package:intl/intl.dart';
import 'package:build_ledger/core/domain/money.dart';

/// Centralized deterministic formatter for PKR currency.
class MoneyFormatter {
  static final NumberFormat _standardFormatter = NumberFormat('#,##0', 'en_US');
  static final NumberFormat _decimalFormatter = NumberFormat('#,##0.00', 'en_US');

  /// Formats [Money] to standard display (e.g. "Rs 18,500" or "Rs 18,500.50").
  /// If the minor units have fractional paisas, includes 2 decimal places.
  static String format(Money money, {bool showPrefix = true, bool forceDecimals = false}) {
    final prefix = showPrefix ? 'Rs ' : '';
    final isNegative = money.isNegative;
    final absMinor = money.minorUnits.abs();

    final whole = absMinor ~/ 100;
    final fraction = absMinor % 100;

    String formattedNumber;
    if (fraction != 0 || forceDecimals) {
      formattedNumber = _decimalFormatter.format(absMinor / 100.0);
    } else {
      formattedNumber = _standardFormatter.format(whole);
    }

    if (isNegative) {
      return '-$prefix$formattedNumber';
    }
    return '$prefix$formattedNumber';
  }

  /// Compact notation for executive dashboard counters and charts (e.g. "Rs 1.25M", "Rs 850K").
  static String formatCompact(Money money, {bool showPrefix = true}) {
    final prefix = showPrefix ? 'Rs ' : '';
    final isNegative = money.isNegative;
    final absMinor = money.minorUnits.abs();
    final major = absMinor / 100.0;

    String compactText;
    if (major >= 1000000) {
      final millions = major / 1000000.0;
      compactText = '${millions.toStringAsFixed(millions >= 10 ? 1 : 2)}M';
    } else if (major >= 1000) {
      final thousands = major / 1000.0;
      compactText = '${thousands.toStringAsFixed(thousands >= 10 ? 1 : 2)}K';
    } else {
      compactText = _standardFormatter.format(major.round());
    }

    if (isNegative) {
      return '-$prefix$compactText';
    }
    return '$prefix$compactText';
  }

  /// Formats accessibility-friendly text for screen readers.
  static String formatAccessible(Money money) {
    final isNegative = money.isNegative;
    final major = (money.minorUnits.abs() / 100.0).round();
    final sign = isNegative ? 'negative ' : '';
    return '$sign$major rupees';
  }
}
