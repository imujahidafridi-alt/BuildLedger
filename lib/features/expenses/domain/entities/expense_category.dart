import 'package:flutter/foundation.dart';

@immutable
class ExpenseCategory {
  final String id;
  final String name;
  final String groupName; // 'Materials', 'Labour', 'Equipment', 'Transport', 'Other'
  final String? iconName;
  final bool isCustom;
  final DateTime createdAt;

  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.groupName,
    this.iconName,
    this.isCustom = false,
    required this.createdAt,
  });
}
