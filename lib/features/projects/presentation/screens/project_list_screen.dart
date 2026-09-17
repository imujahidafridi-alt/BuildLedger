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
              message: 'Start by creating your first construction project to track budgets and expenses.',
              actionLabel: 'Create Project',
              onAction: () => context.push('/projects/new'),
            );
          }

          return RefreshIndicator(
            color: tokens.primary,
            onRefresh: () async => ref.invalidate(projectsListProvider),
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(16, 12, 16, dynamicBottomPadding),
              itemCount: projects.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final project = projects[index];
                return ProjectCard(
                  project: project,
                  onTap: () {
                    ref.read(selectedProjectProvider.notifier).state = project;
                    context.push('/projects/${project.id}');
                  },
                );
              },
            ),
          );
        },
      ),
      // Single, dominant primary CTA per screen (no competing duplicate in AppBar)
      floatingActionButton: hasProjects
          ? ShadButton(
              label: 'New Project',
              icon: const Icon(Icons.add),
              variant: ShadButtonVariant.primary,
              size: ShadButtonSize.large,
              onPressed: () => context.push('/projects/new'),
            )
          : null,
    );
  }
}
