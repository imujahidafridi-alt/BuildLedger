import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/features/dashboard/data/datasources/dashboard_query_dao.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

/// Modal bottom sheet displaying detailed category-wise cost breakdown.
class CategoryBreakdownSheet extends StatefulWidget {
  final Map<String, Money> breakdown;
  final String? projectName;
  final String? projectId;

  const CategoryBreakdownSheet({
    super.key,
    required this.breakdown,
    this.projectName,
    this.projectId,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, Money> breakdown,
    String? projectName,
    String? projectId,
  }) async {
    await ShadSheet.show(
      context: context,
      builder: (context) => CategoryBreakdownSheet(
        breakdown: breakdown,
        projectName: projectName,
        projectId: projectId,
      ),
    );
  }

  @override
  State<CategoryBreakdownSheet> createState() => _CategoryBreakdownSheetState();
}

class _CategoryBreakdownSheetState extends State<CategoryBreakdownSheet> {
  late Map<String, Money> _breakdown;

  @override
  void initState() {
    super.initState();
    _breakdown = Map.from(widget.breakdown);
    if (widget.projectId != null) {
      _loadFullBreakdown();
    }
  }

  Future<void> _loadFullBreakdown() async {
    try {
      final dao = DashboardQueryDao();
      final full = await dao.getFullCategoryBreakdown(widget.projectId!);
      if (mounted && full.isNotEmpty) {
        setState(() {
          _breakdown = full;
        });
      }
    } catch (_) {
      // Gracefully retain initial breakdown
    }
  }

  IconData _getGroupIcon(String group) {
    final g = group.toLowerCase();
    if (g.contains('material') || g.contains('grey') || g.contains('structure') || g.contains('cement') || g.contains('steel')) {
      return Icons.construction_outlined;
    } else if (g.contains('finish') || g.contains('paint') || g.contains('tile') || g.contains('wood')) {
      return Icons.palette_outlined;
    } else if (g.contains('labour') || g.contains('contract') || g.contains('site') || g.contains('worker')) {
      return Icons.engineering_outlined;
    } else if (g.contains('plumb') || g.contains('bath') || g.contains('water') || g.contains('pipe')) {
      return Icons.water_drop_outlined;
    } else if (g.contains('elect') || g.contains('power') || g.contains('cable') || g.contains('light')) {
      return Icons.electrical_services_outlined;
    }
    return Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;
    final totalMinor = _breakdown.values.fold<int>(0, (sum, m) => sum + m.minorUnits);
    final totalMoney = Money.fromMinor(totalMinor);

    if (_breakdown.isEmpty) {
      return ShadSheet(
        title: const Text('Category Cost Breakdown'),
        description: widget.projectName != null ? Text('Project: ${widget.projectName}') : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tokens.muted,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.pie_chart_outline, size: 36, color: tokens.mutedForeground),
            ),
            const SizedBox(height: 16),
            Text(
              'No Expense Categories Recorded',
              style: tokens.typography.h4,
            ),
            const SizedBox(height: 6),
            Text(
              'Record expenses with categories to see your spending breakdown here.',
              style: tokens.typography.muted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ShadButton.outline(
              label: 'Close',
              fullWidth: true,
              size: ShadButtonSize.medium,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }

    return ShadSheet(
      title: const Text('Category Cost Breakdown'),
      description: widget.projectName != null ? Text('Project: ${widget.projectName}') : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Summary Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tokens.muted,
              borderRadius: ShadRadii.roundedMd,
              border: Border.all(color: tokens.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL EXPENDITURE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: tokens.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    MoneyText(
                      totalMoney,
                      style: MoneyTextStyle.headline,
                    ),
                  ],
                ),
                ShadBadge(
                  label: '${_breakdown.length} CATEGORIES',
                  variant: ShadBadgeVariant.neutral,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Category List with Progress Bars
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.48,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: _breakdown.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = _breakdown.entries.elementAt(index);
                final group = entry.key;
                final amount = entry.value;
                final percent = totalMinor > 0
                    ? ((amount.minorUnits / totalMinor) * 100).round()
                    : 0;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: ShadRadii.roundedMd,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/expenses');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: tokens.card,
                        borderRadius: ShadRadii.roundedMd,
                        border: Border.all(color: tokens.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: tokens.muted,
                                  borderRadius: ShadRadii.roundedMd,
                                ),
                                child: Icon(_getGroupIcon(group), size: 16, color: tokens.primary),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  group,
                                  style: tokens.typography.p.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              ShadBadge(
                                label: '$percent%',
                                variant: ShadBadgeVariant.outline,
                                isSmall: true,
                              ),
                              const SizedBox(width: 10),
                              MoneyText(
                                amount,
                                style: MoneyTextStyle.body,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Visual percentage bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: Container(
                              height: 5,
                              width: double.infinity,
                              color: tokens.muted,
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: (percent / 100.0).clamp(0.01, 1.0),
                                child: Container(
                                  color: tokens.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Primary Navigation to full Expense ledger
          ShadButton.outline(
            label: 'View All Expenses',
            icon: Icons.receipt_long_outlined,
            fullWidth: true,
            size: ShadButtonSize.medium,
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/expenses');
            },
          ),
        ],
      ),
    );
  }
}
