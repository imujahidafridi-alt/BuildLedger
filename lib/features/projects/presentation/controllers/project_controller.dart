import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:build_ledger/features/projects/domain/entities/project.dart';
import 'package:build_ledger/features/projects/domain/repositories/project_repository.dart';
import 'package:build_ledger/features/projects/data/repositories/project_repository_impl.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepositoryImpl();
});

/// Fetches active projects.
final projectsListProvider = FutureProvider<List<Project>>((ref) async {
  final repo = ref.watch(projectRepositoryProvider);
  final result = await repo.getProjects(includeArchived: false);
  return result.fold(
    onSuccess: (projects) => projects,
    onFailure: (failure) => throw failure,
  );
});

/// Semantic alias for projectsListProvider (active projects only).
final activeProjectsProvider = projectsListProvider;

/// Fetches archived projects ordered by archived_at DESC.
final archivedProjectsProvider = FutureProvider<List<Project>>((ref) async {
  final repo = ref.watch(projectRepositoryProvider);
  final result = await repo.getArchivedProjects();
  return result.fold(
    onSuccess: (projects) => projects,
    onFailure: (failure) => throw failure,
  );
});

/// Fetches single project by ID (including archived).
final projectByIdProvider = FutureProvider.family<Project?, String>((ref, id) async {
  final repo = ref.watch(projectRepositoryProvider);
  final result = await repo.getProjectById(id);
  return result.fold(
    onSuccess: (project) => project,
    onFailure: (failure) => throw failure,
  );
});

/// Holds the currently active selected project across the entire application.
final selectedProjectProvider = StateProvider<Project?>((ref) {
  final projectsAsync = ref.watch(projectsListProvider);
  return projectsAsync.maybeWhen(
    data: (projects) {
      if (projects.isEmpty) return null;
      // Reconcile with existing selection if possible
      Project? previous;
      try {
        previous = ref.controller.state;
      } catch (_) {
        previous = null;
      }
      final prev = previous;
      if (prev != null && !prev.isArchived && projects.any((p) => p.id == prev.id)) {
        return projects.firstWhere((p) => p.id == prev.id);
      }
      return projects.first;
    },
    orElse: () {
      try {
        final current = ref.controller.state;
        if (current != null && current.isArchived) return null;
        return current;
      } catch (_) {
        return null;
      }
    },
  );
});

/// Controller for creating, updating, archiving, and restoring projects.
class ProjectController extends StateNotifier<AsyncValue<void>> {
  final ProjectRepository _repository;
  final Ref _ref;

  ProjectController(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<bool> createProject(Project project) async {
    state = const AsyncValue.loading();
    final result = await _repository.createProject(project);
    return result.fold(
      onSuccess: (newProject) {
        state = const AsyncValue.data(null);
        _ref.invalidate(projectsListProvider);
        _ref.invalidate(archivedProjectsProvider);
        _ref.read(selectedProjectProvider.notifier).state = newProject;
        return true;
      },
      onFailure: (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> archiveProject(String id) async {
    state = const AsyncValue.loading();
    final result = await _repository.archiveProject(id);
    return result.fold(
      onSuccess: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(projectsListProvider);
        _ref.invalidate(archivedProjectsProvider);
        _ref.invalidate(projectByIdProvider(id));

        // Deterministic selected project safety:
        final currentSelection = _ref.read(selectedProjectProvider);
        if (currentSelection?.id == id) {
          final activeList = _ref.read(projectsListProvider).value ?? [];
          final remaining = activeList.where((p) => p.id != id).toList();
          _ref.read(selectedProjectProvider.notifier).state = remaining.firstOrNull;
        }
        return true;
      },
      onFailure: (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> restoreProject(String id) async {
    state = const AsyncValue.loading();
    final result = await _repository.restoreProject(id);
    return result.fold(
      onSuccess: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(projectsListProvider);
        _ref.invalidate(archivedProjectsProvider);
        _ref.invalidate(projectByIdProvider(id));
        return true;
      },
      onFailure: (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
    );
  }
}

final projectControllerProvider = StateNotifierProvider<ProjectController, AsyncValue<void>>((ref) {
  return ProjectController(ref.watch(projectRepositoryProvider), ref);
});
