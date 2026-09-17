import 'package:build_ledger/core/domain/result.dart';
import 'package:build_ledger/features/projects/domain/entities/project.dart';

abstract class ProjectRepository {
  Future<Result<Project>> createProject(Project project);
  Future<Result<Project>> updateProject(Project project);
  Future<Result<void>> archiveProject(String id);
  Future<Result<void>> restoreProject(String id);
  Future<Result<List<Project>>> getProjects({bool includeArchived = false});
  Future<Result<List<Project>>> getActiveProjects();
  Future<Result<List<Project>>> getArchivedProjects();
  Future<Result<Project?>> getProjectById(String id);
}
