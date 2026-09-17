import 'package:flutter/foundation.dart';

/// The 4 high-level construction cost phases.
enum CostPhase {
  greyStructure,
  finishing,
  externalWorks,
  professionalSite;

  String get displayName {
    switch (this) {
      case CostPhase.greyStructure:
        return 'Grey Structure';
      case CostPhase.finishing:
        return 'Finishing';
      case CostPhase.externalWorks:
        return 'External Works';
      case CostPhase.professionalSite:
        return 'Professional & Site Costs';
    }
  }

  String get code {
    switch (this) {
      case CostPhase.greyStructure:
        return 'GREY_STRUCTURE';
      case CostPhase.finishing:
        return 'FINISHING';
      case CostPhase.externalWorks:
        return 'EXTERNAL_WORKS';
      case CostPhase.professionalSite:
        return 'PROFESSIONAL_SITE';
    }
  }

  static CostPhase fromString(String val) {
    final sanitized = val.trim().toLowerCase().replaceAll('_', '').replaceAll(' ', '');
    if (sanitized.contains('grey')) return CostPhase.greyStructure;
    if (sanitized.contains('finish')) return CostPhase.finishing;
    if (sanitized.contains('external')) return CostPhase.externalWorks;
    if (sanitized.contains('prof') || sanitized.contains('site')) return CostPhase.professionalSite;
    return CostPhase.greyStructure; // Safe fallback
  }
}

/// Domain entity representing an expense category or subcategory in the construction hierarchy.
@immutable
class ExpenseCategory {
  final String id;
  final String? parentId;
  final String name;
  final String code;
  final CostPhase phase;
  final String? iconName;
  final int sortOrder;
  final bool isActive;
  final bool isSystem;
  final List<String> aliases;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined display attributes for parent metadata
  final String? parentName;
  final String? parentCode;

  const ExpenseCategory({
    required this.id,
    this.parentId,
    required this.name,
    required this.code,
    required this.phase,
    this.iconName,
    this.sortOrder = 0,
    this.isActive = true,
    this.isSystem = true,
    this.aliases = const [],
    required this.createdAt,
    required this.updatedAt,
    this.parentName,
    this.parentCode,
  });

  bool get isTopLevel => parentId == null;
  bool get isSubcategory => parentId != null;

  /// Backward-compatibility getter mapping to parent name or phase name.
  String get groupName => parentName ?? phase.displayName;

  /// Backward-compatibility getter for isCustom flag.
  bool get isCustom => !isSystem;

  ExpenseCategory copyWith({
    String? id,
    String? parentId,
    bool clearParent = false,
    String? name,
    String? code,
    CostPhase? phase,
    String? iconName,
    int? sortOrder,
    bool? isActive,
    bool? isSystem,
    List<String>? aliases,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? parentName,
    String? parentCode,
  }) {
    return ExpenseCategory(
      id: id ?? this.id,
      parentId: clearParent ? null : (parentId ?? this.parentId),
      name: name ?? this.name,
      code: code ?? this.code,
      phase: phase ?? this.phase,
      iconName: iconName ?? this.iconName,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      isSystem: isSystem ?? this.isSystem,
      aliases: aliases ?? this.aliases,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      parentName: parentName ?? this.parentName,
      parentCode: parentCode ?? this.parentCode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ExpenseCategory(id: $id, code: $code, name: $name, parentId: $parentId, phase: ${phase.code})';
}
