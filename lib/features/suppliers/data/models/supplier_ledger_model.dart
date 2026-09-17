import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/features/suppliers/domain/entities/supplier_ledger_entry.dart';

class SupplierLedgerModel {
  static SupplierLedgerEntry fromMap(Map<String, dynamic> map) {
    return SupplierLedgerEntry(
      id: map['id'] as String,
      supplierId: map['supplier_id'] as String,
      projectId: map['project_id'] as String?,
      direction: LedgerDirection.fromString(map['direction'] as String),
      entryType: LedgerEntryType.fromString(map['entry_type'] as String),
      amount: Money.fromMinor(map['amount_minor'] as int),
      referenceId: map['reference_id'] as String?,
      description: map['description'] as String,
      entryDate: DateTime.parse(map['entry_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static Map<String, dynamic> toMap(SupplierLedgerEntry entry) {
    return {
      'id': entry.id,
      'supplier_id': entry.supplierId,
      'project_id': entry.projectId,
      'direction': entry.direction.toDbString(),
      'entry_type': entry.entryType.toDbString(),
      'amount_minor': entry.amount.minorUnits,
      'reference_id': entry.referenceId,
      'description': entry.description,
      'entry_date': entry.entryDate.toIso8601String(),
      'created_at': entry.createdAt.toIso8601String(),
      'sync_status': 'local',
    };
  }
}
