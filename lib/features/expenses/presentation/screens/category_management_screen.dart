import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:build_ledger/features/expenses/domain/entities/expense_category.dart';
import 'package:build_ledger/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends ConsumerState<CategoryManagementScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _expandedParentIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddCustomCategoryDialog(BuildContext context, {ExpenseCategory? parentCategory}) {
    final nameController = TextEditingController();
    CostPhase selectedPhase = parentCategory?.phase ?? CostPhase.greyStructure;
    String? selectedParentId = parentCategory?.id;

    final allCategories = ref.read(expenseCategoriesProvider).value ?? [];
    final topLevelCategories = allCategories.where((c) => c.isTopLevel && c.isActive).toList();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final tokens = context.shad;
            return AlertDialog(
              backgroundColor: tokens.popover,
              title: Text(
                parentCategory != null ? 'Add Subcategory under ${parentCategory.name}' : 'Add Custom Category',
                style: tokens.typography.h3,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShadInput(
                      controller: nameController,
                      label: 'Category Name *',
                      hint: 'e.g. Special Precast Panels',
                      autofocus: true,
                    ),
                    const SizedBox(height: ShadSpacing.md),
                    if (parentCategory == null) ...[
                      Text('Cost Phase', style: tokens.typography.small.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: ShadSpacing.xs),
                      ShadSelect<CostPhase>(
                        value: selectedPhase,
                        items: CostPhase.values
                            .map((p) => ShadSelectItem(value: p, label: p.displayName))
                            .toList(),
                        onChanged: (p) {
                          if (p != null) setDialogState(() => selectedPhase = p);
                        },
                      ),
                      const SizedBox(height: ShadSpacing.md),
                      Text('Parent Category (Optional)', style: tokens.typography.small.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: ShadSpacing.xs),
                      ShadSelect<String?>(
                        value: selectedParentId,
                        placeholder: 'None (Top-Level Category)',
                        items: [
                          const ShadSelectItem<String?>(value: null, label: 'None (Top-Level Category)'),
                          ...topLevelCategories.map(
                            (c) => ShadSelectItem<String?>(value: c.id, label: '${c.phase.displayName} · ${c.name}'),
                          ),
                        ],
                        onChanged: (id) {
                          setDialogState(() {
                            selectedParentId = id;
                            if (id != null) {
                              final p = allCategories.firstWhere((c) => c.id == id);
                              selectedPhase = p.phase;
                            }
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('Cancel', style: TextStyle(color: tokens.mutedForeground)),
                ),
                ShadButton(
                  label: 'Create',
                  variant: ShadButtonVariant.primary,
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final success = await ref.read(expenseControllerProvider.notifier).createCustomCategory(
                          name: name,
                          phase: selectedPhase,
                          parentId: selectedParentId,
                        );

                    if (success && dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Custom category created successfully')),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(expenseCategoriesProvider);
    final tokens = context.shad;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Taxonomies'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Custom Category',
            onPressed: () => _openAddCustomCategoryDialog(context),
          ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const ShadLoadingState(message: 'Loading construction taxonomies...'),
        error: (err, _) => ShadErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(expenseCategoriesProvider),
        ),
        data: (allCategories) {
          final q = _searchQuery.toLowerCase().trim();
          final filtered = q.isEmpty
              ? allCategories
              : allCategories.where((c) {
                  return c.name.toLowerCase().contains(q) ||
                      c.aliases.any((a) => a.toLowerCase().contains(q)) ||
                      c.code.toLowerCase().contains(q);
                }).toList();

          final phases = [
            CostPhase.greyStructure,
            CostPhase.finishing,
            CostPhase.externalWorks,
            CostPhase.professionalSite,
          ];

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(ShadSpacing.md),
                child: ShadSearchInput(
                  controller: _searchController,
                  hintText: 'Search categories and aliases...',
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(ShadSpacing.md, 0, ShadSpacing.md, ShadSpacing.xl),
                  itemCount: phases.length,
                  itemBuilder: (context, index) {
                    final phase = phases[index];
                    final topCategories = filtered
                        .where((c) => c.phase == phase && c.isTopLevel)
                        .toList()
                      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

                    if (topCategories.isEmpty && q.isNotEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: ShadSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: ShadSpacing.sm, vertical: 6),
                            child: Row(
                              children: [
                                Icon(Icons.layers_outlined, size: 16, color: tokens.primary),
                                const SizedBox(width: ShadSpacing.xs),
                                Text(
                                  phase.displayName.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: tokens.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ShadCard(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: topCategories.map((topCat) {
                                final subcategories = allCategories
                                    .where((c) => c.parentId == topCat.id)
                                    .toList()
                                  ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

                                final isExpanded = _expandedParentIds.contains(topCat.id) || q.isNotEmpty;

                                return Column(
                                  children: [
                                    ListTile(
                                      dense: true,
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              topCat.name,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: topCat.isActive
                                                    ? tokens.foreground
                                                    : tokens.mutedForeground,
                                                decoration: topCat.isActive ? null : TextDecoration.lineThrough,
                                              ),
                                            ),
                                          ),
                                          if (!topCat.isSystem)
                                            const ShadBadge(label: 'Custom', variant: ShadBadgeVariant.outline),
                                        ],
                                      ),
                                      subtitle: Text(
                                        '${subcategories.length} subcategories · ${topCat.code}',
                                        style: TextStyle(fontSize: 11, color: tokens.mutedForeground),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Switch(
                                            value: topCat.isActive,
                                            activeTrackColor: tokens.primary,
                                            onChanged: (active) {
                                              ref.read(expenseControllerProvider.notifier).toggleCategoryActive(
                                                    categoryId: topCat.id,
                                                    isActive: active,
                                                  );
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              isExpanded ? Icons.expand_less : Icons.expand_more,
                                              size: 20,
                                              color: tokens.mutedForeground,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                if (isExpanded) {
                                                  _expandedParentIds.remove(topCat.id);
                                                } else {
                                                  _expandedParentIds.add(topCat.id);
                                                }
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isExpanded && subcategories.isNotEmpty) ...[
                                      Container(
                                        color: tokens.muted.withValues(alpha: 0.15),
                                        padding: const EdgeInsets.only(left: ShadSpacing.lg),
                                        child: Column(
                                          children: subcategories.map((sub) {
                                            return ListTile(
                                              dense: true,
                                              title: Text(
                                                sub.name,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: sub.isActive
                                                      ? tokens.foreground
                                                      : tokens.mutedForeground,
                                                  decoration: sub.isActive ? null : TextDecoration.lineThrough,
                                                ),
                                              ),
                                               subtitle: Text(
                                                 sub.aliases.isNotEmpty
                                                     ? sub.aliases
                                                         .map((a) => a.trim().replaceAll(RegExp(r'^["\x27\[\]\s]+|["\x27\[\]\s]+$'), '').trim())
                                                         .where((a) => a.isNotEmpty)
                                                         .join(', ')
                                                     : sub.code,
                                                 maxLines: 1,
                                                 overflow: TextOverflow.ellipsis,
                                                 style: TextStyle(fontSize: 11, color: tokens.mutedForeground),
                                               ),
                                              trailing: Switch(
                                                value: sub.isActive,
                                                activeTrackColor: tokens.primary,
                                                onChanged: (active) {
                                                  ref.read(expenseControllerProvider.notifier).toggleCategoryActive(
                                                        categoryId: sub.id,
                                                        isActive: active,
                                                      );
                                                },
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_custom_cat_fab',
        backgroundColor: tokens.primary,
        foregroundColor: tokens.primaryForeground,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('New Category'),
        onPressed: () => _openAddCustomCategoryDialog(context),
      ),
    );
  }
}
