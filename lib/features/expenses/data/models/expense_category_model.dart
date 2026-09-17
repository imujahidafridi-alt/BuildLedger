import 'package:build_ledger/features/expenses/domain/entities/expense_category.dart';

class ExpenseCategoryModel {
  static ExpenseCategory fromMap(Map<String, dynamic> map) {
    List<String> parseAliases(dynamic raw) {
      if (raw == null) return const [];
      if (raw is List) return raw.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
      final str = raw.toString();
      if (str.isEmpty) return const [];
      return str.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }

    final createdAt = map['created_at'] != null
        ? DateTime.parse(map['created_at'] as String)
        : DateTime.now();

    final updatedAt = map['updated_at'] != null
        ? DateTime.parse(map['updated_at'] as String)
        : createdAt;

    // Support both v2 schema and v1 legacy schema fallback
    final phaseRaw = map['phase'] as String? ?? map['group_name'] as String? ?? 'GREY_STRUCTURE';
    final isSystem = map['is_system'] != null
        ? (map['is_system'] as int) == 1
        : (map['is_custom'] as int? ?? 0) != 1;

    return ExpenseCategory(
      id: map['id'] as String,
      parentId: map['parent_id'] as String?,
      name: map['name'] as String,
      code: map['code'] as String? ?? (map['id'] as String).toUpperCase(),
      phase: CostPhase.fromString(phaseRaw),
      iconName: map['icon_name'] as String?,
      sortOrder: map['sort_order'] as int? ?? 0,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      isSystem: isSystem,
      aliases: parseAliases(map['aliases']),
      createdAt: createdAt,
      updatedAt: updatedAt,
      parentName: map['parent_name'] as String?,
      parentCode: map['parent_code'] as String?,
    );
  }

  static Map<String, dynamic> toMap(ExpenseCategory category) {
    return {
      'id': category.id,
      'parent_id': category.parentId,
      'name': category.name,
      'code': category.code,
      'phase': category.phase.code,
      'icon_name': category.iconName,
      'sort_order': category.sortOrder,
      'is_active': category.isActive ? 1 : 0,
      'is_system': category.isSystem ? 1 : 0,
      'aliases': category.aliases.join(','),
      'created_at': category.createdAt.toIso8601String(),
      'updated_at': category.updatedAt.toIso8601String(),
    };
  }
}
