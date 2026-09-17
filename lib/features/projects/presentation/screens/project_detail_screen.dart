import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:build_ledger/features/dashboard/domain/models/project_financial_summary.dart';
import 'package:build_ledger/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:build_ledger/features/dashboard/presentation/widgets/budget_gauge_card.dart';
import 'package:build_ledger/features/dashboard/presentation/widgets/category_spend_card.dart';
import 'package:build_ledger/features/projects/presentation/controllers/project_controller.dart';
import 'package:build_ledger/features/expenses/presentation/widgets/app_expense_tile.dart';
import 'package:build_ledger/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectDao = ref.watch(dashboardQueryDaoProvider);
    final tokens = context.shad;
    final dynamicBottomPadding = MediaQuery.paddingOf(context).bottom + 24;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Overview'),
        actions: [
          IconButton(
            icon: Icon(Icons.archive_outlined, color: tokens.destructive),
            tooltip: 'Archive Project',
            onPressed: () async {
              final confirmed = await ShadConfirmDialog.show(
                context,
                title: 'Archive Project',
                message: 'This project will be archived. It will remain preserved in historical reports but hidden from active lists.',
                confirmLabel: 'Archive',
                isDestructive: true,
              );
              if (confirmed && context.mounted) {
                final success = await ref.read(projectControllerProvider.notifier).archiveProject(projectId);
                if (success && context.mounted) {
                  context.pop();
                }
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<ProjectFinancialSummary>(
        future: projectDao.getProjectFinancialSummary(projectId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ShadLoadingState(message: 'Loading project financials...');
          }
          if (snapshot.hasError) {
            return ShadErrorState(message: snapshot.error.toString());
          }

          final summary = snapshot.data!;

          return ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, dynamicBottomPadding),
            children: [
              BudgetGaugeCard(
                summary: summary,
                onSelectProject: () {},
              ),
              const SizedBox(height: 16),
              CategorySpendCard(categoryBreakdown: summary.categoryBreakdown),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RECENT PROJECT EXPENSES',
                    style: tokens.typography.muted.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: tokens.mutedForeground,
                    ),
                  ),
                  ShadButton(
                    label: 'Add Expense',
                    icon: Icons.add,
                    variant: ShadButtonVariant.primary,
                    size: ShadButtonSize.sm,
                    onPressed: () {
                      ref.read(expenseFilterProvider.notifier).update((f) => f.copyWith(projectId: projectId));
                      context.push('/expenses/new');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (summary.recentExpenses.isEmpty)
                ShadCard(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No expenses recorded for this project yet',
                        style: TextStyle(color: tokens.mutedForeground),
                      ),
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
                    final exp = summary.recentExpenses[index];
                    return AppExpenseTile(expense: exp);
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
