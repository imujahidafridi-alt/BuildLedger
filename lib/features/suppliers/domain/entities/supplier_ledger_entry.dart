import 'package:flutter/foundation.dart';
import 'package:build_ledger/core/domain/money.dart';

enum LedgerDirection {
  credit, // Increases contractor liability / payable to supplier (Purchases, Opening Balance)
  debit;  // Decreases contractor liability / payable to supplier (Payments, Refunds)

  static LedgerDirection fromString(String val) =>
      val.toLowerCase() == 'debit' ? LedgerDirection.debit : LedgerDirection.credit;

  String toDbString() => name;
}

enum LedgerEntryType {
  openingBalance,
  purchase,
  payment,
  adjustment,
  refund;

  static LedgerEntryType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'opening_balance':
        return LedgerEntryType.openingBalance;
      case 'purchase':
        return LedgerEntryType.purchase;
      case 'payment':
        return LedgerEntryType.payment;
      case 'adjustment':
        return LedgerEntryType.adjustment;
      case 'refund':
        return LedgerEntryType.refund;
      default:
        return LedgerEntryType.purchase;
    }
  }

  String toDbString() {
    switch (this) {
      case LedgerEntryType.openingBalance:
        return 'opening_balance';
      case LedgerEntryType.purchase:
        return 'purchase';
      case LedgerEntryType.payment:
        return 'payment';
      case LedgerEntryType.adjustment:
        return 'adjustment';
      case LedgerEntryType.refund:
        return 'refund';
    }
  }

  String get displayName {
    switch (this) {
      case LedgerEntryType.openingBalance:
        return 'Opening Balance';
      case LedgerEntryType.purchase:
        return 'Material Purchase';
      case LedgerEntryType.payment:
        return 'Supplier Payment';
      case LedgerEntryType.adjustment:
        return 'Balance Adjustment';
      case LedgerEntryType.refund:
        return 'Refund / Return';
    }
  }
}

@immutable
class SupplierLedgerEntry {
  final String id;
  final String supplierId;
  final String? projectId;
  final LedgerDirection direction;
  final LedgerEntryType entryType;
  final Money amount;
  final String? referenceId;
  final String description;
  final DateTime entryDate;
  final DateTime createdAt;

  const SupplierLedgerEntry({
    required this.id,
    required this.supplierId,
    this.projectId,
    required this.direction,
    required this.entryType,
    required this.amount,
    this.referenceId,
    required this.description,
    required this.entryDate,
    required this.createdAt,
  });

  bool get isCredit => direction == LedgerDirection.credit;
  bool get isDebit => direction == LedgerDirection.debit;
}
