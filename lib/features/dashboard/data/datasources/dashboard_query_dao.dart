import 'package:build_ledger/core/database/database_helper.dart';
import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/features/dashboard/domain/models/project_financial_summary.dart';
import 'package:build_ledger/features/expenses/data/models/expense_model.dart';

class DashboardQueryDao {
  final DatabaseHelper _dbHelper;

  DashboardQueryDao([DatabaseHelper? dbHelper]) : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<ProjectFinancialSummary> getProjectFinancialSummary(String projectId) async {
    final db = await _dbHelper.database;

    // 1. Fetch Project
    final projectRows = await db.query('projects', where: 'id = ?', whereArgs: [projectId], limit: 1);
    if (projectRows.isEmpty) return ProjectFinancialSummary.empty();

    final projectMap = projectRows.first;
    final projectName = projectMap['name'] as String;
    final budget = Money.fromMinor(projectMap['budget_amount'] as int);

    // 2. Incurred Project Cost: Active Expenses + Unlinked Active Labour
    final expenseCostRow = await db.rawQuery('''
      SELECT COALESCE(SUM(amount_minor), 0) as total
      FROM expenses
      WHERE status = 'active' AND project_id = ?
    ''', [projectId]);
    final expenseCost = expenseCostRow.first['total'] as int;

    final unlinkedLabourRow = await db.rawQuery('''
      SELECT COALESCE(SUM(net_amount_minor), 0) as total
      FROM labour_entries
      WHERE status = 'active' AND project_id = ? AND expense_id IS NULL
    ''', [projectId]);
    final unlinkedLabourCost = unlinkedLabourRow.first['total'] as int;

    final actualCost = Money.fromMinor(expenseCost + unlinkedLabourCost);

    // 3. Cash Outflow: Active non-credit expenses + supplier payments + cash labour advances
    final cashExpenseRow = await db.rawQuery('''
      SELECT COALESCE(SUM(amount_minor), 0) as total
      FROM expenses
      WHERE status = 'active' AND payment_method != 'credit' AND project_id = ?
    ''', [projectId]);
    final cashExpenseOutflow = cashExpenseRow.first['total'] as int;

    final supplierPaymentRow = await db.rawQuery('''
      SELECT COALESCE(SUM(amount_minor), 0) as total
      FROM supplier_ledger
      WHERE entry_type = 'payment' AND project_id = ?
    ''', [projectId]);
    final supplierPaymentOutflow = supplierPaymentRow.first['total'] as int;

    final labourAdvanceRow = await db.rawQuery('''
      SELECT COALESCE(SUM(advance_minor), 0) as total
      FROM labour_entries
      WHERE status = 'active' AND project_id = ? AND expense_id IS NULL
    ''', [projectId]);
    final labourAdvanceOutflow = labourAdvanceRow.first['total'] as int;

    final cashOutflow = Money.fromMinor(cashExpenseOutflow + supplierPaymentOutflow + labourAdvanceOutflow);

    // 4. Supplier Payables: Net credit minus debit for this project
    final supplierPayableRow = await db.rawQuery('''
      SELECT COALESCE(SUM(CASE WHEN direction = 'credit' THEN amount_minor ELSE -amount_minor END), 0) as total
      FROM supplier_ledger
      WHERE project_id = ?
    ''', [projectId]);
    final payableTotal = supplierPayableRow.first['total'] as int;
    final supplierPayables = Money.fromMinor(payableTotal < 0 ? 0 : payableTotal);

    // 5. Remaining Budget & Utilization
    final remainingBudget = budget - actualCost;
    final int utilizationPercent = budget.minorUnits > 0
        ? ((actualCost.minorUnits / budget.minorUnits) * 100).round()
        : 0;

    // 6. Top 5 Category Breakdown (Top-Level Category aggregation)
    final categoryRows = await db.rawQuery('''
      SELECT 
        COALESCE(parent.name, c.name) as top_category_name,
        COALESCE(SUM(e.amount_minor), 0) as category_total
      FROM expenses e
      JOIN expense_categories c ON e.category_id = c.id
      LEFT JOIN expense_categories parent ON c.parent_id = parent.id
      WHERE e.status = 'active' AND e.project_id = ?
      GROUP BY top_category_name
      ORDER BY category_total DESC
      LIMIT 5
    ''', [projectId]);

    final categoryBreakdown = <String, Money>{};
    for (final row in categoryRows) {
      final group = row['top_category_name'] as String;
      final total = Money.fromMinor(row['category_total'] as int);
      categoryBreakdown[group] = total;
    }

    // 7. Recent 5 Active Expenses
    final recentRows = await db.rawQuery('''
      SELECT 
        e.*,
        c.name as category_name,
        parent.name as parent_category_name,
        c.phase as phase,
        COALESCE(parent.name, c.name) as group_name,
        s.name as supplier_name,
        p.name as project_name
      FROM expenses e
      JOIN expense_categories c ON e.category_id = c.id
      LEFT JOIN expense_categories parent ON c.parent_id = parent.id
      LEFT JOIN suppliers s ON e.supplier_id = s.id
      JOIN projects p ON e.project_id = p.id
      WHERE e.status = 'active' AND e.project_id = ?
      ORDER BY e.expense_date DESC, e.created_at DESC
      LIMIT 5
    ''', [projectId]);

    final recentExpenses = recentRows.map(ExpenseModel.fromMap).toList();

    return ProjectFinancialSummary(
      projectId: projectId,
      projectName: projectName,
      budget: budget,
      actualCost: actualCost,
      cashOutflow: cashOutflow,
      supplierPayables: supplierPayables,
      remainingBudget: remainingBudget,
      utilizationPercent: utilizationPercent,
      isOverBudget: actualCost > budget,
      categoryBreakdown: categoryBreakdown,
      recentExpenses: recentExpenses,
    );
  }
}
