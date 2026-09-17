import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/features/labour/domain/entities/labour_entry.dart';

class LabourModel {
  static LabourEntry fromMap(Map<String, dynamic> map) {
    return LabourEntry(
      id: map['id'] as String,
      projectId: map['project_id'] as String,
      workerName: map['worker_name'] as String,
      role: map['role'] as String,
      rate: Money.fromMinor(map['rate_minor'] as int),
      daysX100: map['days_x100'] as int,
      advance: Money.fromMinor(map['advance_minor'] as int),
      netAmount: Money.fromMinor(map['net_amount_minor'] as int),
      entryDate: DateTime.parse(map['entry_date'] as String),
      notes: map['notes'] as String?,
      expenseId: map['expense_id'] as String?,
      isVoided: (map['status'] as String? ?? 'active') == 'voided',
      voidedAt: map['voided_at'] != null ? DateTime.parse(map['voided_at'] as String) : null,
      voidReason: map['void_reason'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      projectName: map['project_name'] as String?,
    );
  }

  static Map<String, dynamic> toMap(LabourEntry entry) {
    return {
      'id': entry.id,
      'project_id': entry.projectId,
      'worker_name': entry.workerName,
      'role': entry.role,
      'rate_minor': entry.rate.minorUnits,
      'days_x100': entry.daysX100,
      'advance_minor': entry.advance.minorUnits,
      'net_amount_minor': entry.netAmount.minorUnits,
      'entry_date': entry.entryDate.toIso8601String(),
      'status': entry.isVoided ? 'voided' : 'active',
      'voided_at': entry.voidedAt?.toIso8601String(),
      'void_reason': entry.voidReason,
      'notes': entry.notes,
      'expense_id': entry.expenseId,
      'created_at': entry.createdAt.toIso8601String(),
      'updated_at': entry.updatedAt.toIso8601String(),
    };
  }
}
