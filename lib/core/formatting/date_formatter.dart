import 'package:intl/intl.dart';

/// Centralized date formatting service ensuring consistent representation across the app.
class DateFormatter {
  static final DateFormat _standardDate = DateFormat('dd MMM yyyy');
  static final DateFormat _shortDate = DateFormat('dd MMM');
  static final DateFormat _monthYear = DateFormat('MMM yyyy');
  static final DateFormat _isoDate = DateFormat('yyyy-MM-dd');
  static final DateFormat _dateTime = DateFormat('dd MMM yyyy, hh:mm a');

  /// Formats date to standard display (e.g. "17 Sep 2026").
  static String format(DateTime date) => _standardDate.format(date);

  /// Formats date to short display (e.g. "17 Sep").
  static String formatShort(DateTime date) => _shortDate.format(date);

  /// Formats to month/year (e.g. "Sep 2026").
  static String formatMonthYear(DateTime date) => _monthYear.format(date);

  /// Formats to ISO 8601 string for deterministic SQLite storage (e.g. "2026-09-17").
  static String formatIso(DateTime date) => _isoDate.format(date);

  /// Parses an ISO 8601 string from SQLite storage.
  static DateTime parseIso(String isoString) => DateTime.parse(isoString);

  /// Formats date with time (e.g. "17 Sep 2026, 10:45 AM").
  static String formatDateTime(DateTime dateTime) => _dateTime.format(dateTime);

  /// Formats relative date for financial lists ("Today", "Yesterday", "17 Sep").
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    final difference = today.difference(target).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference == -1) return 'Tomorrow';

    if (now.year == date.year) {
      return _shortDate.format(date);
    }
    return _standardDate.format(date);
  }
}
