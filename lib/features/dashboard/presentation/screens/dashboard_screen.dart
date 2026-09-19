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
import 'package:build_ledger/features/settings/presentation/controllers/settings_controller.dart';
import 'package:build_ledger/features/settings/presentation/dialogs/contractor_profile_sheet.dart';
import 'package:build_ledger/features/settings/presentation/dialogs/welcome_contractor_sheet.dart';
import 'package:build_ledger/features/settings/presentation/dialogs/currency_selector_sheet.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final repo = ref.read(appSettingsRepositoryProvider);
      final hasSeen = await repo.hasSeenProfileOnboarding();
      final profile = ref.read(contractorProfileProvider);
      if (!hasSeen && !profile.isConfigured && mounted) {
        await WelcomeContractorSheet.show(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;
    final summaryAsync = ref.watch(projectSummaryProvider);
    final projectsAsync = ref.watch(projectsListProvider);
    final profile = ref.watch(contractorProfileProvider);
    final currentCurrency = ref.watch(baseCurrencyProvider);
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
            return ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset),
              children: [
                ShadCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: tokens.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: tokens.primary.withValues(alpha: 0.3)),
                        ),
                        child: Center(
                          child: Icon(Icons.apartment, color: tokens.primary, size: 30),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Welcome to BuildLedger', style: tokens.typography.h3, textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      Text(
                        'Set up your construction firm profile and launch your first project.',
                        style: tokens.typography.muted,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ShadCard(
                  onTap: () => WelcomeContractorSheet.show(context),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: profile.isConfigured
                              ? tokens.success.withValues(alpha: 0.15)
                              : tokens.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Icon(
                            profile.isConfigured ? Icons.check_circle : Icons.business,
                            color: profile.isConfigured ? tokens.success : tokens.warning,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '1. Contractor Profile',
                                    style: tokens.typography.p.copyWith(fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ShadBadge(
                                  label: profile.isConfigured ? 'READY' : 'REQUIRED',
                                  variant: profile.isConfigured
                                      ? ShadBadgeVariant.success
                                      : ShadBadgeVariant.warning,
                                  isSmall: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              profile.isConfigured
                                  ? '${profile.name}${profile.taxId.isNotEmpty ? " • NTN: ${profile.taxId}" : ""}'
                                  : 'Enter company name & NTN for official statements',
                              style: tokens.typography.small.copyWith(color: tokens.mutedForeground),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: tokens.mutedForeground, size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ShadCard(
                  onTap: () => CurrencySelectorSheet.show(context),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: tokens.muted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            currentCurrency.flag,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '2. Base Currency',
                                    style: tokens.typography.p.copyWith(fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ShadBadge(
                                  label: '${currentCurrency.code} (${currentCurrency.symbol})',
                                  variant: ShadBadgeVariant.neutral,
                                  isSmall: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${currentCurrency.name} • Tap to switch standard',
                              style: tokens.typography.small.copyWith(color: tokens.mutedForeground),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: tokens.mutedForeground, size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ShadCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: tokens.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Icon(Icons.add_business, color: tokens.primary, size: 22),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '3. First Construction Project',
                                  style: tokens.typography.p.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'Add your active site to start logging expenses',
                                  style: tokens.typography.small.copyWith(color: tokens.mutedForeground),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ShadButton(
                        label: 'Create Project',
                        icon: const Icon(Icons.add, size: 18),
                        variant: ShadButtonVariant.primary,
                        onPressed: () => context.push('/projects/new'),
                      ),
                    ],
                  ),
                ),
              ],
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
                    if (!profile.isConfigured) ...[
                      ShadCard(
                        onTap: () => ContractorProfileSheet.show(context),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: tokens.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Icon(Icons.business_outlined, color: tokens.warning, size: 20),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Set Up Contractor Profile',
                                    style: tokens.typography.p.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Brand exported PDF reports with your company name & NTN',
                                    style: tokens.typography.small.copyWith(
                                      color: tokens.mutedForeground,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ShadButton.outline(
                              label: 'Set Up',
                              size: ShadButtonSize.small,
                              onPressed: () => ContractorProfileSheet.show(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
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
