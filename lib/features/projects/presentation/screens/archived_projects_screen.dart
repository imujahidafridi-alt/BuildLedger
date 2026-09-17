import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:build_ledger/core/formatting/date_formatter.dart';
import 'package:build_ledger/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:build_ledger/features/projects/domain/entities/project.dart';
import 'package:build_ledger/features/projects/presentation/controllers/project_controller.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

/// Screen displaying all archived construction projects.
///
/// Allows site supervisors and project managers to:
/// 1. Search through archived projects by name, client, or location.
/// 2. Inspect archived date, budget, and recorded historical costs.
/// 3. Safely restore a project back to active status with full data integrity.
/// 4. Tap any project card to view its comprehensive historical financial summary.
class ArchivedProjectsScreen extends ConsumerStatefulWidget {
  const ArchivedProjectsScreen({super.key});

  @override
  ConsumerState<ArchivedProjectsScreen> createState() => _ArchivedProjectsScreenState();
}

class _ArchivedProjectsScreenState extends ConsumerState<ArchivedProjectsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRestore(Project project) async {
    final confirmed = await ShadConfirmDialog.show(
      context,
      title: 'Restore Project',
      message: 'Restore this project?\n\nIt will become available again in the active project list. All existing financial history will remain unchanged.',
      confirmLabel: 'Restore',
    );

    if (!confirmed || !mounted) return;

    final success = await ref.read(projectControllerProvider.notifier).restoreProject(project.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project restored')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;
    final archivedAsync = ref.watch(archivedProjectsProvider);
    final dynamicBottomPadding = MediaQuery.paddingOf(context).bottom + 24;

    return Scaffold(
      appBar: AppBar(
        title: Text('Archived Projects', style: tokens.typography.h3),
      ),
      body: archivedAsync.when(
        loading: () => const ShadLoadingState(message: 'Loading archived projects...'),
        error: (err, _) => ShadErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(archivedProjectsProvider),
        ),
        data: (allArchived) {
          if (allArchived.isEmpty) {
            return const ShadEmptyState(
              icon: Icons.archive_outlined,
              title: 'No Archived Projects',
              message: 'Projects you archive will appear here.\nYou can restore them whenever you need to continue working on them.',
            );
          }

          final query = _searchQuery.trim().toLowerCase();
          final filtered = allArchived.where((p) {
            if (query.isEmpty) return true;
            final matchesName = p.name.toLowerCase().contains(query);
            final matchesClient = p.clientName?.toLowerCase().contains(query) ?? false;
            final matchesLocation = p.location?.toLowerCase().contains(query) ?? false;
            return matchesName || matchesClient || matchesLocation;
          }).toList();

          return RefreshIndicator(
            color: tokens.primary,
            onRefresh: () async => ref.invalidate(archivedProjectsProvider),
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 12, 16, dynamicBottomPadding),
              children: [
                ShadSearchInput(
                  controller: _searchController,
                  hint: 'Search archived projects...',
                  onChanged: (val) => setState(() => _searchQuery = val),
                  onClear: () => setState(() => _searchQuery = ''),
                ),
                const SizedBox(height: 14),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'No matching archived projects found',
                        style: tokens.typography.muted,
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final project = filtered[index];
                      return _ArchivedProjectCard(
                        project: project,
                        onTap: () => context.push('/projects/${project.id}'),
                        onRestore: () => _handleRestore(project),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ArchivedProjectCard extends ConsumerWidget {
  final Project project;
  final VoidCallback onTap;
  final VoidCallback onRestore;

  const _ArchivedProjectCard({
    required this.project,
    required this.onTap,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.shad;
    final financialSummaryAsync = ref.watch(projectFinancialSummaryProvider(project.id));

    return ShadCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name and ARCHIVED status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: tokens.typography.h3,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (project.clientName != null || project.location != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (project.clientName != null) ...[
                            Icon(Icons.person_outline, size: 14, color: tokens.mutedForeground),
                            const SizedBox(width: 4),
                            Text(
                              project.clientName!,
                              style: tokens.typography.muted,
                            ),
                          ],
                          if (project.clientName != null && project.location != null)
                            Text(' • ', style: TextStyle(color: tokens.mutedForeground)),
                          if (project.location != null) ...[
                            Icon(Icons.location_on_outlined, size: 14, color: tokens.mutedForeground),
                            const SizedBox(width: 4),
                            Text(
                              project.location!,
                              style: tokens.typography.muted,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const ShadBadge(
                label: 'ARCHIVED',
                variant: ShadBadgeVariant.neutral,
              ),
            ],
          ),

          // Archived Date
          if (project.archivedAt != null) ...[
            const SizedBox(height: 6),
            Text(
              'Archived: ${DateFormatter.format(project.archivedAt!)}',
              style: tokens.typography.small.copyWith(
                color: tokens.mutedForeground,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          const SizedBox(height: 12),
          const ShadSeparator(),
          const SizedBox(height: 12),

          // Financial metrics & Restore action
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Budget
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BUDGET',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: tokens.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    MoneyText(
                      project.budgetAmount,
                      style: MoneyTextStyle.body,
                    ),
                  ],
                ),
              ),

              // Recorded Cost
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RECORDED COST',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: tokens.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    financialSummaryAsync.when(
                      data: (summary) => MoneyText(
                        summary.actualCost,
                        style: MoneyTextStyle.body,
                      ),
                      loading: () => Text('...', style: tokens.typography.muted),
                      error: (err, stack) => Text('—', style: tokens.typography.muted),
                    ),
                  ],
                ),
              ),

              // Restore button with >=48dp touch target
              ShadButton.outline(
                label: 'Restore',
                icon: Icons.unarchive_outlined,
                size: ShadButtonSize.small,
                onPressed: onRestore,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
