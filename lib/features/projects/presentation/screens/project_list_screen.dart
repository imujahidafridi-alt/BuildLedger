import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:build_ledger/features/projects/presentation/controllers/project_controller.dart';
import 'package:build_ledger/features/projects/presentation/widgets/project_card.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.shad;
    final projectsAsync = ref.watch(projectsListProvider);
    final hasProjects = projectsAsync.maybeWhen(
      data: (projects) => projects.isNotEmpty,
      orElse: () => false,
    );

    final dynamicBottomPadding =
        MediaQuery.paddingOf(context).bottom + 80;

    return Scaffold(
      appBar: AppBar(
        title: Text('Projects', style: tokens.typography.h3),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            tooltip: 'Archived Projects',
            onPressed: () => context.push('/projects/archived'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: projectsAsync.when(
        loading: () => const ShadLoadingState(message: 'Loading construction projects...'),
        error: (err, _) => ShadErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(projectsListProvider),
        ),
        data: (projects) {
          if (projects.isEmpty) {
            return ShadEmptyState(
              icon: Icons.apartment,
              title: 'No Active Projects',
              message: 'You currently have no active projects. Create a new project or view previously archived projects.',
              customAction: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShadButton(
                    label: 'Create Project',
                    onPressed: () => context.push('/projects/new'),
                    size: ShadButtonSize.medium,
                  ),
                  const SizedBox(height: 12),
                  ShadButton.outline(
                    label: 'View Archived Projects',
                    icon: Icons.archive_outlined,
                    onPressed: () => context.push('/projects/archived'),
                    size: ShadButtonSize.medium,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: tokens.primary,
            onRefresh: () async => ref.invalidate(projectsListProvider),
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(16, 12, 16, dynamicBottomPadding),
              itemCount: projects.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index < projects.length) {
                  final project = projects[index];
                  return ProjectCard(
                    project: project,
                    onTap: () {
                      ref.read(selectedProjectProvider.notifier).state = project;
                      context.push('/projects/${project.id}');
                    },
                  );
                }

                // Footer link to Archived Projects
                return Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  child: Center(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => context.push('/projects/archived'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.archive_outlined, size: 16, color: tokens.mutedForeground),
                            const SizedBox(width: 8),
                            Text(
                              'View Archived Projects',
                              style: tokens.typography.muted.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.chevron_right, size: 16, color: tokens.mutedForeground),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      // Consistent floating action button matching Expense and Labour screens
      floatingActionButton: hasProjects
          ? FloatingActionButton.extended(
              heroTag: 'new_project_fab',
              backgroundColor: tokens.primary,
              foregroundColor: tokens.primaryForeground,
              elevation: 2,
              onPressed: () => context.push('/projects/new'),
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                'New Project',
                style: TextStyle(
                  color: tokens.primaryForeground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : null,
    );
  }
}
