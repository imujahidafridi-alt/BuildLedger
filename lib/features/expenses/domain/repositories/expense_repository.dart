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
    CostPhase? phase,
    String? supplierId,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    bool includeVoided = false,
  });
  Future<Result<Expense?>> getExpenseById(String id);

  // Category hierarchy and taxonomy methods
  Future<Result<List<ExpenseCategory>>> getCategories({bool activeOnly = true});
  Future<Result<List<ExpenseCategory>>> getCategoriesByPhase(CostPhase phase, {bool activeOnly = true});
  Future<Result<List<ExpenseCategory>>> getTopLevelCategories({CostPhase? phase, bool activeOnly = true});
  Future<Result<List<ExpenseCategory>>> getSubcategories(String parentId, {bool activeOnly = true});
  Future<Result<List<ExpenseCategory>>> searchCategories(String query, {CostPhase? phase, bool activeOnly = true});
  Future<Result<List<ExpenseCategory>>> getRecentCategories({String? projectId, int limit = 6});
  Future<Result<List<ExpenseCategory>>> getFrequentCategories({String? projectId, int limit = 6});
  Future<Result<ExpenseCategory>> createCustomCategory({
    required String name,
    required CostPhase phase,
    String? parentId,
    String? iconName,
  });
  Future<Result<void>> toggleCategoryActive({
    required String categoryId,
    required bool isActive,
  });
  Future<Result<void>> updateCustomCategory({
    required String categoryId,
    required String name,
    String? iconName,
  });
}
