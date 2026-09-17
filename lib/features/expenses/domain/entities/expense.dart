import 'package:flutter/foundation.dart';
import 'package:build_ledger/core/domain/money.dart';

enum PaymentMethod {
  cash,
  bank,
  credit,
  cheque,
  online;

  static PaymentMethod fromString(String val) {
    switch (val.toLowerCase()) {
      case 'bank':
        return PaymentMethod.bank;
      case 'credit':
        return PaymentMethod.credit;
      case 'cheque':
        return PaymentMethod.cheque;
      case 'online':
        return PaymentMethod.online;
      case 'cash':
      default:
        return PaymentMethod.cash;
    }
  }

  String toDbString() => name;

  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.bank:
        return 'Bank Transfer';
      case PaymentMethod.credit:
        return 'Supplier Credit';
      case PaymentMethod.cheque:
        return 'Cheque';
      case PaymentMethod.online:
        return 'Online / Digital';
    }
  }
}

enum ExpenseStatus {
  active,
  voided;

  static ExpenseStatus fromString(String val) =>
      val.toLowerCase() == 'voided' ? ExpenseStatus.voided : ExpenseStatus.active;

  String toDbString() => name;
}

@immutable
class Expense {
  final String id;
  final String projectId;
  final String categoryId;
  final String? supplierId;
  final Money amount;
  final PaymentMethod paymentMethod;
  final DateTime expenseDate;
  final String? description;
  final String? receiptPath;
  final ExpenseStatus status;
  final DateTime? voidedAt;
  final String? voidReason;
  final String? voidedBy;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined display attributes for fast UI presentation
  final String? categoryName;
  final String? categoryGroupName;
  final String? supplierName;
  final String? projectName;

  const Expense({
    required this.id,
    required this.projectId,
    required this.categoryId,
    this.supplierId,
    required this.amount,
    required this.paymentMethod,
    required this.expenseDate,
    this.description,
    this.receiptPath,
    this.status = ExpenseStatus.active,
    this.voidedAt,
    this.voidReason,
    this.voidedBy,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.categoryName,
    this.categoryGroupName,
    this.supplierName,
    this.projectName,
  });

  bool get isActive => status == ExpenseStatus.active;
  bool get isVoided => status == ExpenseStatus.voided;
  bool get isCredit => paymentMethod == PaymentMethod.credit;
  bool get hasReceipt => receiptPath != null && receiptPath!.isNotEmpty;

  Expense copyWith({
    String? categoryId,
    String? supplierId,
    Money? amount,
    PaymentMethod? paymentMethod,
    DateTime? expenseDate,
    String? description,
    String? receiptPath,
    ExpenseStatus? status,
    DateTime? voidedAt,
    String? voidReason,
    String? voidedBy,
    String? notes,
    DateTime? updatedAt,
    String? categoryName,
    String? categoryGroupName,
    String? supplierName,
    String? projectName,
  }) {
    return Expense(
      id: id,
      projectId: projectId,
      categoryId: categoryId ?? this.categoryId,
      supplierId: supplierId ?? this.supplierId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      expenseDate: expenseDate ?? this.expenseDate,
      description: description ?? this.description,
      receiptPath: receiptPath ?? this.receiptPath,
      status: status ?? this.status,
      voidedAt: voidedAt ?? this.voidedAt,
      voidReason: voidReason ?? this.voidReason,
      voidedBy: voidedBy ?? this.voidedBy,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryName: categoryName ?? this.categoryName,
      categoryGroupName: categoryGroupName ?? this.categoryGroupName,
      supplierName: supplierName ?? this.supplierName,
      projectName: projectName ?? this.projectName,
    );
  }
}
