import 'package:build_ledger/core/domain/result.dart';
import 'package:build_ledger/features/expenses/domain/entities/expense.dart';
import 'package:build_ledger/features/expenses/domain/entities/expense_category.dart';

abstract class ExpenseRepository {
  Future<Result<Expense>> recordExpense(Expense expense, {String? stagedReceiptPath});
  Future<Result<void>> voidExpense({
    required String expenseId,
    required String reason,
    required String actor,
  });
  Future<Result<List<Expense>>> getExpenses({
    String? projectId,
    String? categoryId,
    String? supplierId,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    bool includeVoided = false,
  });
  Future<Result<List<ExpenseCategory>>> getCategories();
  Future<Result<Expense?>> getExpenseById(String id);
}
