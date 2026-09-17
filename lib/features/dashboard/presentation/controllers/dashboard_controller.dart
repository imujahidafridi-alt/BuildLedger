import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:build_ledger/features/dashboard/domain/models/project_financial_summary.dart';
import 'package:build_ledger/features/dashboard/data/datasources/dashboard_query_dao.dart';
import 'package:build_ledger/features/projects/presentation/controllers/project_controller.dart';
import 'package:build_ledger/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:build_ledger/features/suppliers/presentation/controllers/supplier_controller.dart';
import 'package:build_ledger/features/labour/presentation/controllers/labour_controller.dart';

final dashboardQueryDaoProvider = Provider<DashboardQueryDao>((ref) {
  return DashboardQueryDao();
});

/// Watches the active selected project and automatically re-aggregates whenever
/// expenses, supplier ledgers, or labour shifts change.
final projectSummaryProvider = FutureProvider<ProjectFinancialSummary>((ref) async {
  // Subscribe to updates from other features
  ref.watch(filteredExpensesProvider);
  ref.watch(suppliersListProvider);
  ref.watch(labourEntriesProvider);

  final activeProject = ref.watch(selectedProjectProvider);
  if (activeProject == null) {
    return ProjectFinancialSummary.empty();
  }

  final dao = ref.watch(dashboardQueryDaoProvider);
  return await dao.getProjectFinancialSummary(activeProject.id);
});

/// Fetches financial summary for any specific project ID (active or archived).
final projectFinancialSummaryProvider = FutureProvider.family<ProjectFinancialSummary, String>((ref, projectId) async {
  final dao = ref.watch(dashboardQueryDaoProvider);
  return await dao.getProjectFinancialSummary(projectId);
});
