import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:build_ledger/features/expenses/domain/entities/expense.dart';
import 'package:build_ledger/features/expenses/domain/entities/expense_category.dart';
import 'package:build_ledger/features/expenses/domain/repositories/expense_repository.dart';
import 'package:build_ledger/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:build_ledger/features/projects/presentation/controllers/project_controller.dart';
import 'package:build_ledger/features/suppliers/presentation/controllers/supplier_controller.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepositoryImpl();
});

final expenseCategoriesProvider = FutureProvider<List<ExpenseCategory>>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final result = await repo.getCategories();
  return result.fold(
    onSuccess: (categories) => categories,
    onFailure: (failure) => throw failure,
  );
});

final topLevelCategoriesProvider = FutureProvider.family<List<ExpenseCategory>, CostPhase?>((ref, phase) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final result = await repo.getTopLevelCategories(phase: phase);
  return result.fold(
    onSuccess: (cats) => cats,
    onFailure: (failure) => throw failure,
  );
});

final subcategoriesProvider = FutureProvider.family<List<ExpenseCategory>, String>((ref, parentId) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final result = await repo.getSubcategories(parentId);
  return result.fold(
    onSuccess: (cats) => cats,
    onFailure: (failure) => throw failure,
  );
});

final recentCategoriesProvider = FutureProvider<List<ExpenseCategory>>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final activeProject = ref.watch(selectedProjectProvider);
  final result = await repo.getRecentCategories(projectId: activeProject?.id);
  return result.fold(
    onSuccess: (cats) => cats,
    onFailure: (failure) => throw failure,
  );
});

class ExpenseFilterState {
  final String? projectId;
  final String? categoryId;
  final String? subcategoryId;
  final CostPhase? phase;
  final String? supplierId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;
  final bool includeVoided;

  const ExpenseFilterState({
    this.projectId,
    this.categoryId,
    this.subcategoryId,
    this.phase,
    this.supplierId,
    this.startDate,
    this.endDate,
    this.searchQuery,
    this.includeVoided = false,
  });

  ExpenseFilterState copyWith({
    String? projectId,
    String? categoryId,
    String? subcategoryId,
    CostPhase? phase,
    String? supplierId,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    bool? includeVoided,
    bool clearProject = false,
    bool clearCategory = false,
    bool clearSubcategory = false,
    bool clearPhase = false,
    bool clearSupplier = false,
  }) {
    return ExpenseFilterState(
      projectId: clearProject ? null : (projectId ?? this.projectId),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      subcategoryId: clearSubcategory ? null : (subcategoryId ?? this.subcategoryId),
      phase: clearPhase ? null : (phase ?? this.phase),
      supplierId: clearSupplier ? null : (supplierId ?? this.supplierId),
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      searchQuery: searchQuery ?? this.searchQuery,
      includeVoided: includeVoided ?? this.includeVoided,
    );
  }
}

final expenseFilterProvider = StateProvider<ExpenseFilterState>((ref) {
  final activeProject = ref.watch(selectedProjectProvider);
  return ExpenseFilterState(projectId: activeProject?.id);
});

final filteredExpensesProvider = FutureProvider<List<Expense>>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final filter = ref.watch(expenseFilterProvider);

  final result = await repo.getExpenses(
    projectId: filter.projectId,
    categoryId: filter.subcategoryId ?? filter.categoryId,
    phase: filter.phase,
    supplierId: filter.supplierId,
    startDate: filter.startDate,
    endDate: filter.endDate,
    searchQuery: filter.searchQuery,
    includeVoided: filter.includeVoided,
  );

  return result.fold(
    onSuccess: (expenses) => expenses,
    onFailure: (failure) => throw failure,
  );
});

class ExpenseController extends StateNotifier<AsyncValue<void>> {
  final ExpenseRepository _repository;
  final Ref _ref;

  ExpenseController(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<bool> recordExpense(Expense expense, {String? stagedReceiptPath}) async {
    state = const AsyncValue.loading();
    final result = await _repository.recordExpense(expense, stagedReceiptPath: stagedReceiptPath);
    return result.fold(
      onSuccess: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(filteredExpensesProvider);
        _ref.invalidate(recentCategoriesProvider);
        _ref.invalidate(suppliersListProvider);
        return true;
      },
      onFailure: (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> voidExpense({required String expenseId, required String reason}) async {
    state = const AsyncValue.loading();
    final result = await _repository.voidExpense(
      expenseId: expenseId,
      reason: reason,
      actor: 'local_supervisor',
    );
    return result.fold(
      onSuccess: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(filteredExpensesProvider);
        _ref.invalidate(recentCategoriesProvider);
        return true;
      },
      onFailure: (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> createCustomCategory({
    required String name,
    required CostPhase phase,
    String? parentId,
    String? iconName,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.createCustomCategory(
      name: name,
      phase: phase,
      parentId: parentId,
      iconName: iconName,
    );
    return result.fold(
      onSuccess: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(expenseCategoriesProvider);
        _ref.invalidate(topLevelCategoriesProvider);
        return true;
      },
      onFailure: (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> toggleCategoryActive({
    required String categoryId,
    required bool isActive,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.toggleCategoryActive(
      categoryId: categoryId,
      isActive: isActive,
    );
    return result.fold(
      onSuccess: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(expenseCategoriesProvider);
        _ref.invalidate(topLevelCategoriesProvider);
        return true;
      },
      onFailure: (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
    );
  }
}

final expenseControllerProvider = StateNotifierProvider<ExpenseController, AsyncValue<void>>((ref) {
  return ExpenseController(ref.watch(expenseRepositoryProvider), ref);
});
