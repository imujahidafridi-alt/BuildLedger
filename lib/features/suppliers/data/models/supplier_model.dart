import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/features/suppliers/domain/entities/supplier.dart';

class SupplierModel {
  static Supplier fromMap(Map<String, dynamic> map, [Money balance = Money.zero]) {
    return Supplier(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      archivedAt: map['archived_at'] != null ? DateTime.parse(map['archived_at'] as String) : null,
      currentBalance: balance,
    );
  }

  static Map<String, dynamic> toMap(Supplier supplier) {
    return {
      'id': supplier.id,
      'name': supplier.name,
      'phone': supplier.phone,
      'address': supplier.address,
      'notes': supplier.notes,
      'created_at': supplier.createdAt.toIso8601String(),
      'updated_at': supplier.updatedAt.toIso8601String(),
      'archived_at': supplier.archivedAt?.toIso8601String(),
      'sync_status': 'local',
    };
  }
}
