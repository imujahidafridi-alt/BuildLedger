import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:build_ledger/app/theme/app_theme.dart';
import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/core/domain/result.dart';
import 'package:build_ledger/features/expenses/domain/entities/expense.dart';
import 'package:build_ledger/features/expenses/domain/entities/expense_category.dart';
import 'package:build_ledger/features/expenses/domain/repositories/expense_repository.dart';
import 'package:build_ledger/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:build_ledger/features/expenses/presentation/screens/expense_form_screen.dart';
import 'package:build_ledger/features/expenses/presentation/widgets/expense_detail_sheet.dart';
import 'package:build_ledger/features/projects/domain/entities/project.dart';
import 'package:build_ledger/features/projects/presentation/controllers/project_controller.dart';
import 'package:build_ledger/features/suppliers/domain/entities/supplier.dart';
import 'package:build_ledger/features/suppliers/presentation/controllers/supplier_controller.dart';

class _MockExpenseRepo implements ExpenseRepository {
  final List<Expense> expenses = [];

  @override
  Future<Result<Expense>> recordExpense(Expense expense, {String? stagedReceiptPath}) async {
    expenses.add(expense);
    return Result.success(expense);
  }

  @override
  Future<Result<Expense>> updateExpense(Expense expense, {String? stagedReceiptPath}) async {
    final idx = expenses.indexWhere((e) => e.id == expense.id);
    if (idx != -1) {
      expenses[idx] = expense;
    } else {
      expenses.add(expense);
    }
    return Result.success(expense);
  }

  @override
  Future<Result<void>> deleteExpense(String expenseId) async {
    expenses.removeWhere((e) => e.id == expenseId);
    return const Result.success(null);
  }

  @override
  Future<Result<Expense?>> getExpenseById(String id) async {
    final match = expenses.where((e) => e.id == id).firstOrNull;
    return Result.success(match);
  }

  @override
  Future<Result<List<ExpenseCategory>>> getCategories({bool activeOnly = true}) async =>
      const Result.success([]);

  @override
  Future<Result<List<ExpenseCategory>>> getCategoriesByPhase(CostPhase phase, {bool activeOnly = true}) async =>
      const Result.success([]);

  @override
  Future<Result<List<ExpenseCategory>>> getTopLevelCategories({CostPhase? phase, bool activeOnly = true}) async =>
      const Result.success([]);

  @override
  Future<Result<List<ExpenseCategory>>> getSubcategories(String parentId, {bool activeOnly = true}) async =>
      const Result.success([]);

  @override
  Future<Result<List<ExpenseCategory>>> searchCategories(String query, {CostPhase? phase, bool activeOnly = true}) async =>
      const Result.success([]);

  @override
  Future<Result<List<ExpenseCategory>>> getRecentCategories({String? projectId, int limit = 6}) async =>
      const Result.success([]);

  @override
  Future<Result<List<ExpenseCategory>>> getFrequentCategories({String? projectId, int limit = 6}) async =>
      const Result.success([]);

  @override
  Future<Result<ExpenseCategory>> createCustomCategory({
    required String name,
    required CostPhase phase,
    String? parentId,
    String? iconName,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Result<void>> toggleCategoryActive({required String categoryId, required bool isActive}) async =>
      const Result.success(null);

  @override
  Future<Result<void>> updateCustomCategory({required String categoryId, required String name, String? iconName}) async =>
      const Result.success(null);

  @override
  Future<Result<List<Expense>>> getExpenses({
    String? projectId,
    String? categoryId,
    CostPhase? phase,
    String? supplierId,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    bool includeVoided = false,
  }) async =>
      Result.success(List.from(expenses));

  @override
  Future<Result<void>> voidExpense({required String expenseId, required String reason, required String actor}) async =>
      const Result.success(null);
}

void main() {
  late _MockExpenseRepo mockRepo;

  setUp(() {
    mockRepo = _MockExpenseRepo();
  });

  void configureViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('ExpenseDetailSheet displays all creation inputs and handles delete', (tester) async {
    configureViewport(tester);
    final now = DateTime(2026, 9, 18, 10, 30);
    final project = Project(
      id: 'proj-1',
      name: 'Gulberg Commercial Plaza',
      budgetAmount: Money.fromMajor(25000000),
      createdAt: now,
      updatedAt: now,
    );

    final expense = Expense(
      id: 'exp-detail-1',
      projectId: 'proj-1',
      categoryId: 'cat_top_site_earthwork',
      amount: Money.fromMinor(4500000), // Rs 45,000
      paymentMethod: PaymentMethod.cash,
      expenseDate: now,
      description: 'Excavation machinery rental & diesel',
      notes: 'Paid on site to driver Tariq',
      createdAt: now,
      updatedAt: now,
      projectName: 'Gulberg Commercial Plaza',
      categoryName: 'Site Earthwork & Excavation',
      categoryGroupName: 'Pre-Construction',
    );
    await mockRepo.recordExpense(expense);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseRepositoryProvider.overrideWithValue(mockRepo),
          selectedProjectProvider.overrideWith((ref) => project),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => ExpenseDetailSheet.show(context, expense),
                child: const Text('Open Expense'),
              ),
            ),
          ),
        ),
      ),
    );

    // Tap to open sheet
    await tester.tap(find.text('Open Expense'));
    await tester.pumpAndSettle();

    // Verify all creation inputs are visible on the sheet
    expect(find.text('Gulberg Commercial Plaza'), findsWidgets); // Project
    expect(find.text('Site Earthwork & Excavation'), findsWidgets); // Category
    expect(find.text('Excavation machinery rental & diesel'), findsOneWidget); // Description
    expect(find.text('Paid on site to driver Tariq'), findsOneWidget); // Notes
    expect(find.text('Cash'), findsWidgets); // Payment Method
    expect(find.text('ACTIVE'), findsOneWidget); // Status
    expect(find.text('Edit Expense'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    // Test Delete confirmation dialog
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete Expense?'), findsOneWidget);

    // Confirm Delete button inside ShadConfirmDialog
    final deleteButtons = find.text('Delete Expense');
    expect(deleteButtons, findsWidgets);
    await tester.tap(deleteButtons.last);
    await tester.pumpAndSettle();

    // Verify deleted from repo
    final check = await mockRepo.getExpenseById('exp-detail-1');
    expect(check.dataOrNull, isNull);
  });

  testWidgets('ExpenseFormScreen pre-populates all inputs in Edit mode and updates repository', (tester) async {
    configureViewport(tester);
    final now = DateTime(2026, 9, 18, 10, 30);
    final project = Project(
      id: 'proj-edit',
      name: 'DHA Phase 6 Villa',
      budgetAmount: Money.fromMajor(18000000),
      createdAt: now,
      updatedAt: now,
    );

    final expense = Expense(
      id: 'exp-edit-1',
      projectId: 'proj-edit',
      categoryId: 'cat_mat_cement',
      amount: Money.fromMinor(3500000), // Rs 35,000
      paymentMethod: PaymentMethod.bank,
      expenseDate: now,
      description: 'Original description',
      notes: 'Original note',
      createdAt: now,
      updatedAt: now,
    );
    await mockRepo.recordExpense(expense);

    final testCategory = ExpenseCategory(
      id: 'cat_mat_cement',
      name: 'Cement',
      code: 'MAT_CEMENT',
      phase: CostPhase.greyStructure,
      sortOrder: 1,
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseRepositoryProvider.overrideWithValue(mockRepo),
          projectsListProvider.overrideWith((ref) => Future.value([project])),
          selectedProjectProvider.overrideWith((ref) => project),
          expenseCategoriesProvider.overrideWith((ref) => Future.value([testCategory])),
          recentCategoriesProvider.overrideWith((ref) => Future.value([testCategory])),
          suppliersListProvider.overrideWith((ref) => Future.value(<Supplier>[])),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: ExpenseFormScreen(initialExpense: expense),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Edit mode headers & pre-populated fields
    expect(find.text('Edit Expense'), findsOneWidget);
    expect(find.text('Update Expense'), findsOneWidget);
    expect(find.text('Original description'), findsOneWidget);
    expect(find.text('Original note'), findsOneWidget);

    // Edit description
    final descField = find.widgetWithText(TextFormField, 'Original description');
    await tester.enterText(descField, 'Updated 40 Bags Cement');
    await tester.pumpAndSettle();

    // Tap Update Expense
    await tester.tap(find.text('Update Expense'));
    await tester.pumpAndSettle();

    // Verify repository updated
    final updated = await mockRepo.getExpenseById('exp-edit-1');
    expect(updated.dataOrNull?.description, 'Updated 40 Bags Cement');
  });
}
