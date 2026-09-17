import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/features/expenses/domain/entities/expense.dart';

class ExpenseModel {
  static Expense fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      projectId: map['project_id'] as String,
      categoryId: map['category_id'] as String,
      supplierId: map['supplier_id'] as String?,
      amount: Money.fromMinor(map['amount_minor'] as int),
      paymentMethod: PaymentMethod.fromString(map['payment_method'] as String),
      expenseDate: DateTime.parse(map['expense_date'] as String),
      description: map['description'] as String?,
      receiptPath: map['receipt_path'] as String?,
      status: ExpenseStatus.fromString(map['status'] as String),
      voidedAt: map['voided_at'] != null ? DateTime.parse(map['voided_at'] as String) : null,
      voidReason: map['void_reason'] as String?,
      voidedBy: map['voided_by'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      categoryName: map['category_name'] as String?,
      categoryGroupName: map['group_name'] as String?,
      supplierName: map['supplier_name'] as String?,
      projectName: map['project_name'] as String?,
    );
  }

  static Map<String, dynamic> toMap(Expense expense) {
    return {
      'id': expense.id,
      'project_id': expense.projectId,
      'category_id': expense.categoryId,
      'supplier_id': expense.supplierId,
      'amount_minor': expense.amount.minorUnits,
      'payment_method': expense.paymentMethod.toDbString(),
      'expense_date': expense.expenseDate.toIso8601String(),
      'description': expense.description,
      'receipt_path': expense.receiptPath,
      'status': expense.status.toDbString(),
      'voided_at': expense.voidedAt?.toIso8601String(),
      'void_reason': expense.voidReason,
      'voided_by': expense.voidedBy,
      'notes': expense.notes,
      'created_at': expense.createdAt.toIso8601String(),
      'updated_at': expense.updatedAt.toIso8601String(),
      'sync_status': 'local',
      'server_version': 1,
    };
  }
}
