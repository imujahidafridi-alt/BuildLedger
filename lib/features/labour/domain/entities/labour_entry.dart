import 'package:flutter/foundation.dart';
import 'package:build_ledger/core/domain/money.dart';

@immutable
class LabourEntry {
  final String id;
  final String projectId;
  final String workerName;
  final String role; // 'Mason (Mistri)', 'Mazdoor', 'Plumber', etc.
  final Money rate; // Daily wage rate
  final int daysX100; // Fixed-point: 100 = 1.0 day, 150 = 1.5 days
  final Money advance; // Advance paid on site
  final Money netAmount; // ((rate * daysX100) / 100) - advance
  final DateTime entryDate;
  final String? notes;
  final String? expenseId; // Optional link to expense table
  final bool isVoided;
  final DateTime? voidedAt;
  final String? voidReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined project name for display
  final String? projectName;

  const LabourEntry({
    required this.id,
    required this.projectId,
    required this.workerName,
    required this.role,
    required this.rate,
    required this.daysX100,
    required this.advance,
    required this.netAmount,
    required this.entryDate,
    this.notes,
    this.expenseId,
    this.isVoided = false,
    this.voidedAt,
    this.voidReason,
    required this.createdAt,
    required this.updatedAt,
    this.projectName,
  });

  /// Formatted days worked (e.g. "1.5 days" or "1 day")
  String get formattedDays {
    final major = daysX100 ~/ 100;
    final fraction = daysX100 % 100;
    if (fraction == 0) return '$major ${major == 1 ? "day" : "days"}';
    return '${(daysX100 / 100.0).toStringAsFixed(1)} days';
  }

  /// Calculates deterministic net wage
  static Money calculateNetWage({
    required Money rate,
    required int daysX100,
    required Money advance,
  }) {
    final grossMinor = (rate.minorUnits * daysX100) ~/ 100;
    final netMinor = grossMinor - advance.minorUnits;
    return Money.fromMinor(netMinor < 0 ? 0 : netMinor);
  }
}
