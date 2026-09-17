import 'package:uuid/uuid.dart';
import 'package:build_ledger/core/database/database_helper.dart';
import 'package:build_ledger/core/database/transaction_runner.dart';
import 'package:build_ledger/core/domain/result.dart';
import 'package:build_ledger/core/errors/app_failure.dart';
import 'package:build_ledger/features/projects/domain/entities/project.dart';
import 'package:build_ledger/features/projects/domain/repositories/project_repository.dart';
import 'package:build_ledger/features/projects/data/models/project_model.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final DatabaseHelper _dbHelper;
  final TransactionRunner _transactionRunner;

  ProjectRepositoryImpl({
    DatabaseHelper? dbHelper,
    TransactionRunner? transactionRunner,
  })  : _dbHelper = dbHelper ?? DatabaseHelper(),
        _transactionRunner = transactionRunner ?? TransactionRunner();

  @override
  Future<Result<Project>> createProject(Project project) async {
    try {
      await _transactionRunner.run((txn) async {
        await txn.insert('projects', ProjectModel.toMap(project));
        await txn.insert('audit_logs', {
          'id': const Uuid().v4(),
          'entity_type': 'project',
          'entity_id': project.id,
          'action': 'create',
          'actor': 'local_user',
          'payload_before': null,
          'payload_after': project.name,
          'timestamp': DateTime.now().toIso8601String(),
        });
      });
      return Result.success(project);
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to create project: $e'));
    }
  }

  @override
  Future<Result<Project>> updateProject(Project project) async {
    try {
      final db = await _dbHelper.database;
      final count = await db.update(
        'projects',
        ProjectModel.toMap(project),
        where: 'id = ?',
        whereArgs: [project.id],
      );
      if (count == 0) {
        return Result.failure(const NotFoundFailure('Project not found'));
      }
      return Result.success(project);
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to update project: $e'));
    }
  }

  @override
  Future<Result<void>> archiveProject(String id) async {
    try {
      final now = DateTime.now().toIso8601String();
      await _transactionRunner.run((txn) async {
        final count = await txn.update(
          'projects',
          {
            'status': 'archived',
            'archived_at': now,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        if (count == 0) {
          throw Exception('Project not found');
        }
        await txn.insert('audit_logs', {
          'id': const Uuid().v4(),
          'entity_type': 'project',
          'entity_id': id,
          'action': 'archive',
          'actor': 'local_user',
          'payload_before': null,
          'payload_after': 'archived at $now',
          'timestamp': now,
        });
      });
      return const Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to archive project: $e'));
    }
  }

  @override
  Future<Result<void>> restoreProject(String id) async {
    try {
      final now = DateTime.now().toIso8601String();
      await _transactionRunner.run((txn) async {
        final count = await txn.update(
          'projects',
          {
            'status': 'active',
            'archived_at': null,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        if (count == 0) {
          throw Exception('Project not found');
        }
        await txn.insert('audit_logs', {
          'id': const Uuid().v4(),
          'entity_type': 'project',
          'entity_id': id,
          'action': 'restore',
          'actor': 'local_user',
          'payload_before': null,
          'payload_after': 'restored at $now',
          'timestamp': now,
        });
      });
      return const Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to restore project: $e'));
    }
  }

  @override
  Future<Result<List<Project>>> getProjects({bool includeArchived = false}) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps;
      if (includeArchived) {
        maps = await db.query('projects', orderBy: 'created_at DESC');
      } else {
        maps = await db.query(
          'projects',
          where: 'status = ?',
          whereArgs: ['active'],
          orderBy: 'created_at DESC',
        );
      }
      final projects = maps.map(ProjectModel.fromMap).toList();
      return Result.success(projects);
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to fetch projects: $e'));
    }
  }

  @override
  Future<Result<List<Project>>> getActiveProjects() => getProjects(includeArchived: false);

  @override
  Future<Result<List<Project>>> getArchivedProjects() async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        'projects',
        where: 'status = ?',
        whereArgs: ['archived'],
        orderBy: 'archived_at DESC, updated_at DESC',
      );
      final projects = maps.map(ProjectModel.fromMap).toList();
      return Result.success(projects);
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to fetch archived projects: $e'));
    }
  }

  @override
  Future<Result<Project?>> getProjectById(String id) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        'projects',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isEmpty) {
        return const Result.success(null);
      }
      return Result.success(ProjectModel.fromMap(maps.first));
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to fetch project: $e'));
    }
  }
}
