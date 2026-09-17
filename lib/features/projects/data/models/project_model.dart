import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/features/projects/domain/entities/project.dart';

class ProjectModel {
  static Project fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      clientName: map['client_name'] as String?,
      location: map['location'] as String?,
      budgetAmount: Money.fromMinor(map['budget_amount'] as int),
      startDate: map['start_date'] != null ? DateTime.parse(map['start_date'] as String) : null,
      expectedEndDate: map['expected_end_date'] != null ? DateTime.parse(map['expected_end_date'] as String) : null,
      status: ProjectStatus.fromString(map['status'] as String),
      currency: map['currency'] as String? ?? 'PKR',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      archivedAt: map['archived_at'] != null ? DateTime.parse(map['archived_at'] as String) : null,
    );
  }

  static Map<String, dynamic> toMap(Project project) {
    return {
      'id': project.id,
      'name': project.name,
      'description': project.description,
      'client_name': project.clientName,
      'location': project.location,
      'budget_amount': project.budgetAmount.minorUnits,
      'start_date': project.startDate?.toIso8601String(),
      'expected_end_date': project.expectedEndDate?.toIso8601String(),
      'status': project.status.toDbString(),
      'currency': project.currency,
      'created_at': project.createdAt.toIso8601String(),
      'updated_at': project.updatedAt.toIso8601String(),
      'archived_at': project.archivedAt?.toIso8601String(),
      'sync_status': 'local',
      'server_version': 1,
    };
  }
}
