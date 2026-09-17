import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:build_ledger/features/expenses/domain/entities/expense_category.dart';
import 'package:build_ledger/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:build_ledger/features/expenses/presentation/widgets/app_expense_tile.dart';
import 'package:build_ledger/features/expenses/presentation/widgets/expense_detail_sheet.dart';
import 'package:build_ledger/features/projects/presentation/controllers/project_controller.dart';
import 'package:build_ledger/features/projects/presentation/widgets/project_selector_sheet.dart';
import 'package:build_ledger/shared/dialogs/app_void_dialog.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  final _searchController = TextEditingController();
  CostPhase? _selectedPhase;

  final List<({String label, CostPhase? phase})> _phaseFilters = const [
    (label: 'All', phase: null),
    (label: 'Grey Structure', phase: CostPhase.greyStructure),
    (label: 'Finishing', phase: CostPhase.finishing),
    (label: 'External Works', phase: CostPhase.externalWorks),
    (label: 'Professional & Site', phase: CostPhase.professionalSite),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onVoidExpense(String expenseId) async {
    final reason = await AppVoidDialog.show(context, entityName: 'Expense');
    if (reason != null && reason.trim().isNotEmpty) {
      final success = await ref.read(expenseControllerProvider.notifier).voidExpense(
            expenseId: expenseId,
            reason: reason,
          );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense voided and excluded from project spend')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(filteredExpensesProvider);
    final selectedProject = ref.watch(selectedProjectProvider);
    final filter = ref.watch(expenseFilterProvider);
    final tokens = context.shad;

    final hasExpenses = expensesAsync.maybeWhen(
      data: (expenses) => expenses.isNotEmpty,
      orElse: () => false,
    );

    final dynamicBottomPadding =
        MediaQuery.paddingOf(context).bottom + kBottomNavigationBarHeight + 16;

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () async {
            final picked = await ProjectSelectorSheet.show(context, ref);
            if (picked != null) {
              ref.read(selectedProjectProvider.notifier).state = picked;
              ref.read(expenseFilterProvider.notifier).update((f) => f.copyWith(projectId: picked.id));
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    selectedProject?.name ?? 'All Projects',
                    style: tokens.typography.h3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, size: 20, color: tokens.mutedForeground),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              filter.includeVoided ? Icons.visibility : Icons.visibility_off_outlined,
              color: filter.includeVoided ? tokens.destructive : tokens.mutedForeground,
            ),
            tooltip: filter.includeVoided ? 'Hide Voided' : 'Show Voided',
            onPressed: () {
              ref.read(expenseFilterProvider.notifier).update(
                    (f) => f.copyWith(includeVoided: !f.includeVoided),
                  );
            },
          ),
          IconButton(
            icon: Icon(Icons.flash_on, color: tokens.primary),
            tooltip: 'Quick Supervisor Mode',
            onPressed: () => context.push('/expenses/quick'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: ShadSearchInput(
              controller: _searchController,
              hint: 'Search description, supplier, category...',
              onChanged: (val) {
                ref.read(expenseFilterProvider.notifier).update(
                      (f) => f.copyWith(searchQuery: val),
                    );
              },
            ),
          ),

          // Horizontal Phase Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ShadTabs<({String label, CostPhase? phase})>(
              values: _phaseFilters,
              selectedValue: _phaseFilters.firstWhere(
                (f) => f.phase == _selectedPhase,
                orElse: () => _phaseFilters.first,
              ),
              scrollable: true,
              labelBuilder: (item) => item.label,
              onTabSelected: (item) {
                setState(() => _selectedPhase = item.phase);
                ref.read(expenseFilterProvider.notifier).update((f) {
                  return f.copyWith(
                    phase: item.phase,
                    clearPhase: item.phase == null,
                  );
                });
              },
            ),
          ),
          const SizedBox(height: 8),

          // Expense List
          Expanded(
            child: expensesAsync.when(
              loading: () => const ShadLoadingState(message: 'Loading expenses...'),
              error: (err, _) => ShadErrorState(
                message: err.toString(),
                onRetry: () => ref.invalidate(filteredExpensesProvider),
              ),
              data: (expenses) {
                if (expenses.isEmpty) {
                  return ShadEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No Expenses Recorded',
                    description: selectedProject != null
                        ? 'No expenses logged yet for ${selectedProject.name}.'
                        : 'Record daily materials, labour, transport, and site purchases.',
                    actionLabel: 'Record Expense',
                    onAction: () => context.push('/expenses/new'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(filteredExpensesProvider),
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, dynamicBottomPadding),
                    itemCount: expenses.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      return AppExpenseTile(
                        expense: expense,
                        onTap: () => ExpenseDetailSheet.show(context, expense),
                        onVoid: expense.isActive ? () => _onVoidExpense(expense.id) : null,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: hasExpenses
          ? FloatingActionButton.extended(
              heroTag: 'new_expense_fab',
              backgroundColor: tokens.primary,
              foregroundColor: tokens.primaryForeground,
              elevation: 2,
              onPressed: () => context.push('/expenses/new'),
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                'New Expense',
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

