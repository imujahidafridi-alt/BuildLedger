import 'package:build_ledger/features/expenses/domain/entities/expense_category.dart';

class ExpenseCategoryModel {
  static ExpenseCategory fromMap(Map<String, dynamic> map) {
    return ExpenseCategory(
      id: map['id'] as String,
      name: map['name'] as String,
      groupName: map['group_name'] as String,
      iconName: map['icon_name'] as String?,
      isCustom: (map['is_custom'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static Map<String, dynamic> toMap(ExpenseCategory category) {
    return {
      'id': category.id,
      'name': category.name,
      'group_name': category.groupName,
      'icon_name': category.iconName,
      'is_custom': category.isCustom ? 1 : 0,
      'created_at': category.createdAt.toIso8601String(),
    };
  }
}
