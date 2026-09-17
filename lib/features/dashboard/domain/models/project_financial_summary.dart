import 'package:flutter/foundation.dart';
import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/features/expenses/domain/entities/expense.dart';

/// Authoritative financial summary read model derived directly from database queries.
/// Prevents UI screens from independently calculating slightly different numbers.
@immutable
class ProjectFinancialSummary {
  final String projectId;
  final String projectName;
  final Money budget;
  
  // Pillar 1: Incurred Project Cost (Total value committed to site, regardless of cash or credit)
  final Money actualCost;
  
  // Pillar 2: Cash Outflow (Actual cash/bank disbursed out-of-pocket)
  final Money cashOutflow;
  
  // Pillar 3: Supplier Payable (Unpaid debt across vendor credit purchases and payments)
  final Money supplierPayables;
  
  // Derived Budget Control
  final Money remainingBudget; // budget - actualCost
  final int utilizationPercent; // (actualCost / budget) * 100
  final bool isOverBudget; // actualCost > budget

  // Category breakdown: groupName -> Money
  final Map<String, Money> categoryBreakdown;
  
  // Recent 5-10 active transactions
  final List<Expense> recentExpenses;

  const ProjectFinancialSummary({
    required this.projectId,
    required this.projectName,
    required this.budget,
    required this.actualCost,
    required this.cashOutflow,
    required this.supplierPayables,
    required this.remainingBudget,
    required this.utilizationPercent,
    required this.isOverBudget,
    required this.categoryBreakdown,
    required this.recentExpenses,
  });

  static ProjectFinancialSummary empty() {
    return const ProjectFinancialSummary(
      projectId: '',
      projectName: 'No Active Project',
      budget: Money.zero,
      actualCost: Money.zero,
      cashOutflow: Money.zero,
      supplierPayables: Money.zero,
      remainingBudget: Money.zero,
      utilizationPercent: 0,
      isOverBudget: false,
      categoryBreakdown: {},
      recentExpenses: [],
    );
  }
}
