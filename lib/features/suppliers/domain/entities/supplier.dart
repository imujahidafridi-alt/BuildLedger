import 'package:flutter/foundation.dart';
import 'package:build_ledger/core/domain/money.dart';

@immutable
class Supplier {
  final String id;
  final String name;
  final String? phone;
  final String? address;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
  final Money currentBalance; // Derived dynamically from ledger: credits - debits

  const Supplier({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
    this.currentBalance = Money.zero,
  });

  bool get isArchived => archivedAt != null;

  Supplier copyWith({
    String? name,
    String? phone,
    String? address,
    String? notes,
    DateTime? updatedAt,
    DateTime? archivedAt,
    Money? currentBalance,
  }) {
    return Supplier(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      currentBalance: currentBalance ?? this.currentBalance,
    );
  }
}
