import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:build_ledger/features/projects/domain/entities/project.dart';
import 'package:build_ledger/features/projects/presentation/controllers/project_controller.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

/// Modal bottom sheet allowing site supervisors or contractors to swiftly switch projects.
class ProjectSelectorSheet extends StatefulWidget {
  final List<Project> projects;
  final Project? currentSelected;

  const ProjectSelectorSheet({
    super.key,
    required this.projects,
    this.currentSelected,
  });

  static Future<Project?> show(BuildContext context, WidgetRef ref) async {
    final projects = ref.read(projectsListProvider).value ?? [];
    final current = ref.read(selectedProjectProvider);

    return await ShadSheet.show<Project>(
      context: context,
      builder: (context) => ProjectSelectorSheet(
        projects: projects,
        currentSelected: current,
      ),
    );
  }

  @override
  State<ProjectSelectorSheet> createState() => _ProjectSelectorSheetState();
}

class _ProjectSelectorSheetState extends State<ProjectSelectorSheet> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;

    final filtered = widget.projects.where((p) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(query) ||
          (p.location != null && p.location!.toLowerCase().contains(query)) ||
          (p.clientName != null && p.clientName!.toLowerCase().contains(query));
    }).toList();

    return ShadSheet(
      title: const Text('Select Active Project'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.projects.length > 3) ...[
            ShadSearchInput(
              controller: _searchController,
              hint: 'Search projects by name or location...',
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 12),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No matching projects found',
                        style: TextStyle(color: tokens.mutedForeground),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final project = filtered[index];
                      final isSelected = widget.currentSelected?.id == project.id;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => Navigator.of(context).pop(project),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? tokens.primary.withValues(alpha: 0.12)
                                  : tokens.card,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? tokens.primary : tokens.border,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        project.name,
                                        style: tokens.typography.p.copyWith(
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                          color: tokens.foreground,
                                        ),
                                      ),
                                      if (project.location != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          project.location!,
                                          style: tokens.typography.small.copyWith(
                                            color: tokens.mutedForeground,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                MoneyText(
                                  project.budgetAmount,
                                  style: MoneyTextStyle.caption,
                                ),
                                if (isSelected) ...[
                                  const SizedBox(width: 8),
                                  Icon(Icons.check_circle, color: tokens.primary, size: 18),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
