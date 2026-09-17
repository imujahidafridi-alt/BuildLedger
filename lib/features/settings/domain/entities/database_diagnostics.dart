import 'package:flutter/foundation.dart';

/// Diagnostic telemetry and table metrics for the local SQLite database.
@immutable
class DatabaseDiagnostics {
  final int fileSizeBytes;
  final String sqliteVersion;
  final String journalMode;
  final String databasePath;
  final int projectCount;
  final int expenseCount;
  final int supplierCount;
  final int labourCount;
  final int categoryCount;

  const DatabaseDiagnostics({
    required this.fileSizeBytes,
    required this.sqliteVersion,
    required this.journalMode,
    required this.databasePath,
    required this.projectCount,
    required this.expenseCount,
    required this.supplierCount,
    required this.labourCount,
    required this.categoryCount,
  });

  /// Human-readable storage size (KB or MB)
  String get formattedSize {
    if (fileSizeBytes <= 0) return '0 KB';
    final kb = fileSizeBytes / 1024.0;
    if (kb < 1024.0) {
      return '${kb.toStringAsFixed(1)} KB';
    }
    final mb = kb / 1024.0;
    return '${mb.toStringAsFixed(2)} MB';
  }

  int get totalRecords =>
      projectCount + expenseCount + supplierCount + labourCount + categoryCount;
}
