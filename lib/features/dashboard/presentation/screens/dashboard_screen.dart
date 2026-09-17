import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:build_ledger/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:build_ledger/features/dashboard/presentation/widgets/budget_gauge_card.dart';
import 'package:build_ledger/features/dashboard/presentation/widgets/category_spend_card.dart';
import 'package:build_ledger/features/expenses/presentation/widgets/app_expense_tile.dart';
import 'package:build_ledger/features/expenses/presentation/widgets/expense_detail_sheet.dart';
import 'package:build_ledger/features/projects/presentation/controllers/project_controller.dart';
import 'package:build_ledger/features/projects/presentation/widgets/project_selector_sheet.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.shad;
    final summaryAsync = ref.watch(projectSummaryProvider);
    final projectsAsync = ref.watch(projectsListProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom + 24;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: tokens.primary,
                borderRadius: ShadRadii.roundedMd,
              ),
              child: Center(
                child: Icon(Icons.account_balance, color: tokens.primaryForeground, size: 18),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'BuildLedger',
              style: tokens.typography.h3,
            ),
          ],
        ),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: Icon(Icons.flash_on, color: tokens.primary, size: 20),
            tooltip: 'Quick Supervisor Mode',
            onPressed: () => context.push('/expenses/quick'),
          ),
          IconButton(
            icon: Icon(Icons.picture_as_pdf_outlined, color: tokens.foreground, size: 20),
            tooltip: 'Generate PDF Report',
            onPressed: () => context.push('/reports'),
          ),
        ],
      ),
      body: projectsAsync.when(
        loading: () => const ShadLoadingState(message: 'Initializing BuildLedger...'),
        error: (err, _) => ShadErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(projectsListProvider),
        ),
        data: (projects) {
          if (projects.isEmpty) {
            return ShadEmptyState(
              icon: Icons.apartment,
              title: 'Welcome to BuildLedger',
              message: 'Create your first construction project to track expenses, suppliers, and site budgets.',
              actionLabel: 'Create Project',
              onAction: () => context.push('/projects/new'),
            );
          }

          return summaryAsync.when(
            loading: () => const ShadLoadingState(message: 'Aggregating financial data...'),
            error: (err, _) => ShadErrorState(
              message: err.toString(),
              onRetry: () => ref.invalidate(projectSummaryProvider),
            ),
            data: (summary) {
              return RefreshIndicator(
                color: tokens.primary,
                onRefresh: () async {
                  ref.invalidate(projectSummaryProvider);
                  ref.invalidate(projectsListProvider);
                },
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset),
                  children: [
                    // 1. Budget Gauge & Financial Pillars Card
                    BudgetGaugeCard(
                      summary: summary,
                      onSelectProject: () async {
                        final picked = await ProjectSelectorSheet.show(context, ref);
                        if (picked != null) {
                          ref.read(selectedProjectProvider.notifier).state = picked;
                          ref.invalidate(projectSummaryProvider);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // 2. Primary Action Bar (Clean ShadCN Actions with >=48dp hit area)
                    Row(
                      children: [
                        Expanded(
                          child: ShadButton(
                            label: 'Expense',
                            icon: const Icon(Icons.add),
                            variant: ShadButtonVariant.primary,
                            size: ShadButtonSize.medium,
                            onPressed: () => context.push('/expenses/new'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ShadButton.outline(
                            label: 'Labour',
                            icon: const Icon(Icons.engineering),
                            size: ShadButtonSize.medium,
                            onPressed: () => context.push('/labour/new'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ShadButton.outline(
                            label: 'Vendors',
                            icon: const Icon(Icons.store),
                            size: ShadButtonSize.medium,
                            onPressed: () => context.push('/suppliers'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 3. Category Spending Breakdown
                    CategorySpendCard(
                      categoryBreakdown: summary.categoryBreakdown,
                      projectName: summary.projectName,
                      projectId: summary.projectId,
                    ),
                    const SizedBox(height: 20),

                    // 4. Recent Activity Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RECENT EXPENSES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: tokens.mutedForeground,
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: ShadRadii.roundedMd,
                            onTap: () => context.go('/expenses'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              child: Text(
                                'View All',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: tokens.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 5. Recent Expenses List
                    if (summary.recentExpenses.isEmpty)
                      ShadCard(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'No expenses logged yet for this project',
                            style: tokens.typography.muted,
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: summary.recentExpenses.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final expense = summary.recentExpenses[index];
                          return AppExpenseTile(
                            expense: expense,
                            onTap: () => ExpenseDetailSheet.show(context, expense),
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
