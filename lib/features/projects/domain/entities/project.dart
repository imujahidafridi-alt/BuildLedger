import 'package:flutter/foundation.dart';
import 'package:build_ledger/core/domain/money.dart';

enum ProjectStatus {
  active,
  completed,
  archived;

  static ProjectStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return ProjectStatus.completed;
      case 'archived':
        return ProjectStatus.archived;
      case 'active':
      default:
        return ProjectStatus.active;
    }
  }

  String toDbString() => name;
}

@immutable
class Project {
  final String id;
  final String name;
  final String? description;
  final String? clientName;
  final String? location;
  final Money budgetAmount;
  final DateTime? startDate;
  final DateTime? expectedEndDate;
  final ProjectStatus status;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;

  const Project({
    required this.id,
    required this.name,
    this.description,
    this.clientName,
    this.location,
    required this.budgetAmount,
    this.startDate,
    this.expectedEndDate,
    this.status = ProjectStatus.active,
    this.currency = 'PKR',
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
  });

  bool get isActive => status == ProjectStatus.active;
  bool get isArchived => status == ProjectStatus.archived;
  bool get isCompleted => status == ProjectStatus.completed;

  Project copyWith({
    String? name,
    String? description,
    String? clientName,
    String? location,
    Money? budgetAmount,
    DateTime? startDate,
    DateTime? expectedEndDate,
    ProjectStatus? status,
    String? currency,
    DateTime? updatedAt,
    DateTime? archivedAt,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      clientName: clientName ?? this.clientName,
      location: location ?? this.location,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      startDate: startDate ?? this.startDate,
      expectedEndDate: expectedEndDate ?? this.expectedEndDate,
      status: status ?? this.status,
      currency: currency ?? this.currency,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }
}
