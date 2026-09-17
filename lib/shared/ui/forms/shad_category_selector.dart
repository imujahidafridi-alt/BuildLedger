import 'package:flutter/material.dart';
import 'package:build_ledger/core/design_system/tokens.dart';
import 'package:build_ledger/core/design_system/radii.dart';
import 'package:build_ledger/core/design_system/spacing.dart';
import 'package:build_ledger/features/expenses/domain/entities/expense_category.dart';
import 'package:build_ledger/shared/ui/components/sheet/shad_sheet.dart';
import 'package:build_ledger/shared/ui/components/keyboard/keyboard_dismissible.dart';
import 'package:build_ledger/shared/ui/forms/shad_search_input.dart';
import 'package:build_ledger/shared/ui/components/badge/shad_badge.dart';

/// Business-logic independent ShadCN category selector.
/// Supports hierarchical navigation (Cost Phase -> Top-Level -> Subcategory)
/// and real-time normalized search with Pakistani aliases.
class ShadCategorySelector extends StatelessWidget {
  final ExpenseCategory? value;
  final List<ExpenseCategory> categories;
  final List<ExpenseCategory> recentCategories;
  final ValueChanged<ExpenseCategory?> onChanged;
  final String? label;
  final String placeholder;
  final bool enabled;
  final String? errorText;

  const ShadCategorySelector({
    super.key,
    this.value,
    required this.categories,
    this.recentCategories = const [],
    required this.onChanged,
    this.label = 'Category *',
    this.placeholder = 'Select category...',
    this.enabled = true,
    this.errorText,
  });

  String _getDisplayLabel() {
    if (value == null) return placeholder;
    if (value!.isSubcategory && value!.parentId != null) {
      final parent = categories.cast<ExpenseCategory?>().firstWhere(
            (c) => c?.id == value!.parentId,
            orElse: () => null,
          );
      if (parent != null) {
        return '${parent.name} · ${value!.name}';
      }
    }
    return value!.name;
  }

  void _openSheet(BuildContext context) async {
    if (!enabled) return;

    final picked = await ShadSheet.show<ExpenseCategory>(
      context: context,
      builder: (ctx) => _CategoryPickerSheet(
        categories: categories,
        recentCategories: recentCategories,
        selectedCategory: value,
      ),
    );

    if (picked != null) {
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;
    final hasValue = value != null;
    final isError = errorText != null && errorText!.isNotEmpty;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label ?? 'Category',
      value: hasValue ? _getDisplayLabel() : placeholder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isError ? tokens.destructive : tokens.foreground,
              ),
            ),
            const SizedBox(height: ShadSpacing.xs),
          ],
          InkWell(
            onTap: enabled ? () => _openSheet(context) : null,
            borderRadius: ShadRadii.roundedMd,
            child: Container(
              height: 48, // 48dp minimum touch target
              padding: const EdgeInsets.symmetric(horizontal: ShadSpacing.md),
              decoration: BoxDecoration(
                color: enabled ? tokens.card : tokens.muted.withValues(alpha: 0.3),
                borderRadius: ShadRadii.roundedMd,
                border: Border.all(
                  color: isError
                      ? tokens.destructive
                      : enabled
                          ? tokens.border
                          : tokens.border.withValues(alpha: 0.4),
                  width: isError ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 18,
                    color: isError
                        ? tokens.destructive
                        : hasValue
                            ? tokens.primary
                            : tokens.mutedForeground,
                  ),
                  const SizedBox(width: ShadSpacing.sm),
                  Expanded(
                    child: Text(
                      _getDisplayLabel(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
                        color: !enabled
                            ? tokens.mutedForeground.withValues(alpha: 0.5)
                            : hasValue
                                ? tokens.foreground
                                : tokens.mutedForeground,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.unfold_more_rounded,
                    size: 18,
                    color: tokens.mutedForeground,
                  ),
                ],
              ),
            ),
          ),
          if (isError) ...[
            const SizedBox(height: ShadSpacing.xs),
            Text(
              errorText!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: tokens.destructive,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryPickerSheet extends StatefulWidget {
  final List<ExpenseCategory> categories;
  final List<ExpenseCategory> recentCategories;
  final ExpenseCategory? selectedCategory;

  const _CategoryPickerSheet({
    required this.categories,
    required this.recentCategories,
    this.selectedCategory,
  });

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _searchQuery = '';
  CostPhase? _selectedPhase;
  ExpenseCategory? _drilledParent;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim();
    if (q != _searchQuery) {
      setState(() {
        _searchQuery = q;
        if (q.isNotEmpty) {
          _drilledParent = null; // Clear drilldown on search
        }
      });
    }
  }

  static String _normalize(String s) {
    return s.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  List<ExpenseCategory> _getSearchResults() {
    final q = _normalize(_searchQuery);
    if (q.isEmpty) return const [];

    final categoryMap = {for (final c in widget.categories) c.id: c};
    final scored = <_ScoredItem>[];

    for (final cat in widget.categories) {
      if (!cat.isActive) continue;
      if (_selectedPhase != null && cat.phase != _selectedPhase) continue;

      final parentName = cat.parentId != null ? categoryMap[cat.parentId]?.name : null;
      final normName = _normalize(cat.name);
      final normParent = parentName != null ? _normalize(parentName) : '';
      final normCode = _normalize(cat.code);

      int score = 0;
      if (normName == q) {
        score = 100;
      } else if (cat.aliases.any((a) => _normalize(a) == q)) {
        score = 95;
      } else if (normName.startsWith(q)) {
        score = 85;
      } else if (cat.aliases.any((a) => _normalize(a).startsWith(q))) {
        score = 80;
      } else if (normName.contains(q)) {
        score = 70;
      } else if (cat.aliases.any((a) => _normalize(a).contains(q))) {
        score = 65;
      } else if (normParent.isNotEmpty && normParent.contains(q)) {
        score = 50;
      } else if (normCode.contains(q)) {
        score = 40;
      }

      if (score > 0) {
        scored.add(_ScoredItem(cat, score, parentName));
      }
    }

    scored.sort((a, b) {
      if (b.score != a.score) return b.score.compareTo(a.score);
      return a.category.sortOrder.compareTo(b.category.sortOrder);
    });

    return scored.map((s) => s.category).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;
    final isSearching = _searchQuery.isNotEmpty;
    final isDrilled = _drilledParent != null;

    final sheetHeight = MediaQuery.sizeOf(context).height * 0.82;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: sheetHeight),
      child: Material(
        color: tokens.popover,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(ShadRadii.xl)),
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: tokens.border, width: 1.0)),
          ),
          child: KeyboardDismissible(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: ShadSpacing.sm),
                decoration: BoxDecoration(
                  color: tokens.border,
                  borderRadius: ShadRadii.roundedFull,
                ),
              ),
            ),

            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ShadSpacing.lg, vertical: ShadSpacing.xs),
              child: Row(
                children: [
                  if (isDrilled) ...[
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      color: tokens.foreground,
                      onPressed: () => setState(() => _drilledParent = null),
                    ),
                    const SizedBox(width: ShadSpacing.xs),
                  ],
                  Expanded(
                    child: Text(
                      isDrilled ? _drilledParent!.name : 'Select Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: tokens.foreground,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    color: tokens.mutedForeground,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Search Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ShadSpacing.lg, vertical: ShadSpacing.xs),
              child: ShadSearchInput(
                controller: _searchController,
                focusNode: _searchFocusNode,
                hintText: 'Search categories (e.g. saria, cement, rait)...',
                textInputAction: TextInputAction.search,
              ),
            ),

            // Phase Filter Tabs (Only shown when not searching and not drilled down)
            if (!isSearching && !isDrilled) _buildPhaseSelector(tokens),

            const Divider(height: 1),

            // Content Body
            Flexible(
              child: isSearching
                  ? _buildSearchResultsList(tokens)
                  : isDrilled
                      ? _buildSubcategoriesList(tokens)
                      : _buildHierarchyList(tokens),
            ),
          ],
        ),
      ),
      ),
      ),
    );
  }

  Widget _buildPhaseSelector(ShadTokens tokens) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: ShadSpacing.lg, vertical: ShadSpacing.xs),
      child: Row(
        children: [
          _buildPhaseChip(null, 'All', tokens),
          const SizedBox(width: ShadSpacing.xs),
          _buildPhaseChip(CostPhase.greyStructure, 'Grey Structure', tokens),
          const SizedBox(width: ShadSpacing.xs),
          _buildPhaseChip(CostPhase.finishing, 'Finishing', tokens),
          const SizedBox(width: ShadSpacing.xs),
          _buildPhaseChip(CostPhase.externalWorks, 'External Works', tokens),
          const SizedBox(width: ShadSpacing.xs),
          _buildPhaseChip(CostPhase.professionalSite, 'Professional & Site', tokens),
        ],
      ),
    );
  }

  Widget _buildPhaseChip(CostPhase? phase, String label, ShadTokens tokens) {
    final isSelected = _selectedPhase == phase;
    return InkWell(
      onTap: () => setState(() => _selectedPhase = phase),
      borderRadius: ShadRadii.roundedFull,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: ShadSpacing.sm + 2, vertical: ShadSpacing.xs + 1),
        decoration: BoxDecoration(
          color: isSelected ? tokens.primary : tokens.muted.withValues(alpha: 0.4),
          borderRadius: ShadRadii.roundedFull,
          border: Border.all(
            color: isSelected ? tokens.primary : tokens.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? tokens.primaryForeground : tokens.mutedForeground,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultsList(ShadTokens tokens) {
    final results = _getSearchResults();
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(ShadSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 40, color: tokens.mutedForeground),
              const SizedBox(height: ShadSpacing.sm),
              Text(
                'No categories found for "$_searchQuery"',
                style: TextStyle(fontSize: 14, color: tokens.mutedForeground),
              ),
            ],
          ),
        ),
      );
    }

    final categoryMap = {for (final c in widget.categories) c.id: c};

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: ShadSpacing.xs),
      itemCount: results.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: tokens.border.withValues(alpha: 0.5)),
      itemBuilder: (context, index) {
        final cat = results[index];
        final parentName = cat.parentId != null ? categoryMap[cat.parentId]?.name : null;
        final isSelected = widget.selectedCategory?.id == cat.id;

        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: ShadSpacing.lg, vertical: 2),
          title: Text(
            cat.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? tokens.primary : tokens.foreground,
            ),
          ),
          subtitle: Text(
            parentName != null ? '${cat.phase.displayName} · $parentName' : cat.phase.displayName,
            style: TextStyle(fontSize: 12, color: tokens.mutedForeground),
          ),
          trailing: isSelected
              ? Icon(Icons.check_rounded, size: 18, color: tokens.primary)
              : null,
          onTap: () => Navigator.of(context).pop(cat),
        );
      },
    );
  }

  Widget _buildHierarchyList(ShadTokens tokens) {
    // 1. Recent Categories Row (if available)
    final topLevel = widget.categories
        .where((c) => c.isTopLevel && c.isActive)
        .where((c) => _selectedPhase == null || c.phase == _selectedPhase)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: ShadSpacing.xs),
      children: [
        if (widget.recentCategories.isNotEmpty && _selectedPhase == null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(ShadSpacing.lg, ShadSpacing.xs, ShadSpacing.lg, ShadSpacing.xs),
            child: Text(
              'RECENT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: tokens.mutedForeground,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ShadSpacing.lg),
            child: Wrap(
              spacing: ShadSpacing.xs,
              runSpacing: ShadSpacing.xs,
              children: widget.recentCategories.take(6).map((cat) {
                final isSelected = widget.selectedCategory?.id == cat.id;
                return ActionChip(
                  label: Text(cat.name),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? tokens.primaryForeground : tokens.foreground,
                  ),
                  backgroundColor: isSelected ? tokens.primary : tokens.muted.withValues(alpha: 0.4),
                  side: BorderSide(color: isSelected ? tokens.primary : tokens.border),
                  onPressed: () => Navigator.of(context).pop(cat),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: ShadSpacing.sm),
          Divider(height: 1, color: tokens.border.withValues(alpha: 0.5)),
        ],

        // Top-level categories grouped or listed
        ...topLevel.map((cat) {
          final subcount = widget.categories.where((c) => c.parentId == cat.id && c.isActive).length;
          final isSelected = widget.selectedCategory?.id == cat.id;

          return ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: ShadSpacing.lg, vertical: 2),
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: tokens.muted.withValues(alpha: 0.5),
              child: Icon(
                _resolveIcon(cat.iconName),
                size: 16,
                color: tokens.primary,
              ),
            ),
            title: Text(
              cat.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? tokens.primary : tokens.foreground,
              ),
            ),
            subtitle: Text(
              cat.phase.displayName,
              style: TextStyle(fontSize: 11, color: tokens.mutedForeground),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (subcount > 0)
                  ShadBadge(
                    label: '$subcount',
                    variant: ShadBadgeVariant.outline,
                  ),
                const SizedBox(width: ShadSpacing.xs),
                Icon(Icons.chevron_right_rounded, size: 18, color: tokens.mutedForeground),
              ],
            ),
            onTap: () {
              if (subcount > 0) {
                setState(() => _drilledParent = cat);
              } else {
                Navigator.of(context).pop(cat);
              }
            },
          );
        }),
      ],
    );
  }

  Widget _buildSubcategoriesList(ShadTokens tokens) {
    final parent = _drilledParent!;
    final subcategories = widget.categories
        .where((c) => c.parentId == parent.id && c.isActive)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: ShadSpacing.xs),
      children: [
        // Option to select the top-level category itself
        ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: ShadSpacing.lg, vertical: 2),
          title: Text(
            'All ${parent.name} (General)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: tokens.foreground,
            ),
          ),
          subtitle: Text(
            'Use top-level category without subcategory',
            style: TextStyle(fontSize: 11, color: tokens.mutedForeground),
          ),
          trailing: widget.selectedCategory?.id == parent.id
              ? Icon(Icons.check_rounded, size: 18, color: tokens.primary)
              : null,
          onTap: () => Navigator.of(context).pop(parent),
        ),
        Divider(height: 1, color: tokens.border.withValues(alpha: 0.5)),

        // Subcategories
        ...subcategories.map((sub) {
          final isSelected = widget.selectedCategory?.id == sub.id;
          final aliasHint = sub.aliases.isNotEmpty ? sub.aliases.take(3).join(', ') : null;

          return ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: ShadSpacing.lg, vertical: 2),
            title: Text(
              sub.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? tokens.primary : tokens.foreground,
              ),
            ),
            subtitle: aliasHint != null
                ? Text(
                    aliasHint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: tokens.mutedForeground),
                  )
                : null,
            trailing: isSelected
                ? Icon(Icons.check_rounded, size: 18, color: tokens.primary)
                : null,
            onTap: () => Navigator.of(context).pop(sub),
          );
        }),
      ],
    );
  }

  IconData _resolveIcon(String? name) {
    switch (name) {
      case 'landscape':
        return Icons.landscape_outlined;
      case 'foundation':
        return Icons.foundation_outlined;
      case 'corporate_fare':
        return Icons.corporate_fare_outlined;
      case 'view_module':
        return Icons.view_module_outlined;
      case 'construction':
        return Icons.construction_outlined;
      case 'format_paint':
        return Icons.format_paint_outlined;
      case 'water_drop':
        return Icons.water_drop_outlined;
      case 'plumbing':
        return Icons.plumbing_outlined;
      case 'local_fire_department':
        return Icons.local_fire_department_outlined;
      case 'electrical_services':
        return Icons.electrical_services_outlined;
      case 'grid_view':
        return Icons.grid_view_outlined;
      case 'door_front_door':
        return Icons.door_front_door_outlined;
      case 'fence':
        return Icons.fence_outlined;
      case 'carpenter':
        return Icons.carpenter_outlined;
      case 'countertops':
        return Icons.countertops_outlined;
      case 'bathtub':
        return Icons.bathtub_outlined;
      case 'roofing':
        return Icons.roofing_outlined;
      case 'park':
        return Icons.park_outlined;
      case 'light':
        return Icons.light_outlined;
      case 'engineering':
        return Icons.engineering_outlined;
      case 'badge':
        return Icons.badge_outlined;
      case 'more_horiz':
      default:
        return Icons.category_outlined;
    }
  }
}

class _ScoredItem {
  final ExpenseCategory category;
  final int score;
  final String? parentName;
  _ScoredItem(this.category, this.score, this.parentName);
}
