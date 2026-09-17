import 'package:flutter/foundation.dart';

/// Structured application logger respecting release mode and security guidelines.
class AppLogger {
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag] ' : '';
      debugPrint('[DEBUG] $tagStr$message');
    }
  }

  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag] ' : '';
      debugPrint('[INFO] $tagStr$message');
    }
  }

  static void warning(String message, {String? tag, Object? error}) {
    final tagStr = tag != null ? '[$tag] ' : '';
    debugPrint('[WARN] $tagStr$message ${error != null ? "- Error: $error" : ""}');
  }

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final tagStr = tag != null ? '[$tag] ' : '';
    debugPrint('[ERROR] $tagStr$message');
    if (error != null) {
      debugPrint('Exception: $error');
    }
    if (stackTrace != null && kDebugMode) {
      debugPrint('StackTrace:\n$stackTrace');
    }
  }
}
