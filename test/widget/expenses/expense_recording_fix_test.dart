import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:build_ledger/core/database/database_helper.dart';
import 'package:build_ledger/core/design_system/theme.dart';
import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/core/domain/result.dart';
import 'package:build_ledger/core/errors/app_failure.dart';
import 'package:build_ledger/features/expenses/domain/entities/expense.dart';
import 'package:build_ledger/features/expenses/domain/entities/expense_category.dart';
import 'package:build_ledger/features/expenses/domain/repositories/expense_repository.dart';
import 'package:build_ledger/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:build_ledger/features/expenses/presentation/screens/expense_form_screen.dart';
import 'package:build_ledger/features/expenses/presentation/screens/quick_expense_screen.dart';
import 'package:build_ledger/features/projects/domain/entities/project.dart';
import 'package:build_ledger/features/projects/presentation/controllers/project_controller.dart';
import 'package:build_ledger/features/suppliers/domain/entities/supplier.dart';
import 'package:build_ledger/features/suppliers/presentation/controllers/supplier_controller.dart';
import 'package:build_ledger/shared/ui/forms/shad_select.dart';
import 'package:build_ledger/shared/ui/forms/shad_category_selector.dart';

class _MockFailingExpenseRepository implements ExpenseRepository {
  @override
  Future<Result<Expense>> recordExpense(Expense expense, {String? stagedReceiptPath}) async {
    return const Result.failure(DatabaseFailure('Disk write failed during transaction'));
  }

  @override
  Future<Result<List<ExpenseCategory>>> getCategories({bool activeOnly = true}) async {
    return const Result.success([]);
  }

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
  Future<Result<Expense?>> getExpenseById(String id) async => const Result.success(null);

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
      const Result.success([]);

  @override
  Future<Result<void>> voidExpense({required String expenseId, required String reason, required String actor}) async =>
      const Result.success(null);
}

class _MockSuccessfulExpenseRepository implements ExpenseRepository {
  Expense? recordedExpense;

  @override
  Future<Result<Expense>> recordExpense(Expense expense, {String? stagedReceiptPath}) async {
    recordedExpense = expense;
    return Result.success(expense);
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
  Future<Result<Expense?>> getExpenseById(String id) async => const Result.success(null);

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
      const Result.success([]);

  @override
  Future<Result<void>> voidExpense({required String expenseId, required String reason, required String actor}) async =>
      const Result.success(null);
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  final now = DateTime(2026, 3, 15);

  final testProjectA = Project(
    id: 'proj_A',
    name: 'Al-Madina Commercial Center',
    location: 'Islamabad',
    budgetAmount: const Money(500000000), // Rs 5,000,000
    status: ProjectStatus.active,
    createdAt: now,
    updatedAt: now,
  );

  final testProjectB = Project(
    id: 'proj_B',
    name: 'Bahria Residential Villa',
    location: 'Rawalpindi',
    budgetAmount: const Money(300000000), // Rs 3,000,000
    status: ProjectStatus.active,
    createdAt: now,
    updatedAt: now,
  );

  final testCategory = ExpenseCategory(
    id: 'cat_mat_cement',
    name: 'Cement',
    code: 'MAT_CEMENT',
    phase: CostPhase.greyStructure,
    sortOrder: 1,
    createdAt: now,
    updatedAt: now,
  );

  void configureViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('A. ShadSelect Form State Synchronization', () {
    testWidgets('Synchronizes external value changes (null -> A -> B -> null)', (tester) async {
      final formKey = GlobalKey<FormState>();

      Widget buildTestHarness(String? value) {
        return MaterialApp(
          theme: ShadTheme.darkTheme,
          home: Scaffold(
            body: Form(
              key: formKey,
              child: StatefulBuilder(
                builder: (context, setState) {
                  return ShadSelect<String>(
                    label: 'Project',
                    value: value,
                    items: const [
                      ShadSelectItem(value: 'proj_1', label: 'Project 1'),
                      ShadSelectItem(value: 'proj_2', label: 'Project 2'),
                    ],
                    onChanged: (_) {},
                    validator: (v) => v == null ? 'Required' : null,
                  );
                },
              ),
            ),
          ),
        );
      }

      // 1. Initial build with null value
      await tester.pumpWidget(buildTestHarness(null));
      await tester.pumpAndSettle();

      final selectFinder = find.byType(ShadSelect<String>);
      expect(selectFinder, findsOneWidget);
      FormFieldState<String> fieldState = tester.state(selectFinder);
      expect(fieldState.value, isNull);

      // Validation fails when null
      expect(formKey.currentState!.validate(), isFalse);

      // 2. External update: null -> 'proj_1'
      await tester.pumpWidget(buildTestHarness('proj_1'));
      await tester.pumpAndSettle();

      fieldState = tester.state(selectFinder);
      expect(fieldState.value, equals('proj_1'));
      expect(find.text('Project 1'), findsOneWidget);
      expect(formKey.currentState!.validate(), isTrue);

      // 3. External update: 'proj_1' -> 'proj_2'
      await tester.pumpWidget(buildTestHarness('proj_2'));
      await tester.pumpAndSettle();

      fieldState = tester.state(selectFinder);
      expect(fieldState.value, equals('proj_2'));
      expect(find.text('Project 2'), findsOneWidget);
      expect(formKey.currentState!.validate(), isTrue);

      // 4. External update: 'proj_2' -> null
      await tester.pumpWidget(buildTestHarness(null));
      await tester.pumpAndSettle();

      fieldState = tester.state(selectFinder);
      expect(fieldState.value, isNull);
      expect(formKey.currentState!.validate(), isFalse);
    });
  });

  group('B & C. ExpenseFormScreen Project Auto-Selection and User Selection Preservation', () {
    testWidgets('Automatically resolves active project on first open', (tester) async {
      configureViewport(tester);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectsListProvider.overrideWith((ref) => Future.value([testProjectA, testProjectB])),
            selectedProjectProvider.overrideWith((ref) => testProjectA),
            expenseCategoriesProvider.overrideWith((ref) => Future.value([testCategory])),
            recentCategoriesProvider.overrideWith((ref) => Future.value([testCategory])),
            suppliersListProvider.overrideWith((ref) => Future.value(<Supplier>[])),
          ],
          child: MaterialApp(
            theme: ShadTheme.darkTheme,
            home: const ExpenseFormScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Project A should be automatically resolved and displayed
      expect(find.text(testProjectA.name), findsOneWidget);
    });

    testWidgets('User project selection is preserved and does not get overwritten', (tester) async {
      configureViewport(tester);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectsListProvider.overrideWith((ref) => Future.value([testProjectA, testProjectB])),
            selectedProjectProvider.overrideWith((ref) => testProjectA),
            expenseCategoriesProvider.overrideWith((ref) => Future.value([testCategory])),
            recentCategoriesProvider.overrideWith((ref) => Future.value([testCategory])),
            suppliersListProvider.overrideWith((ref) => Future.value(<Supplier>[])),
          ],
          child: MaterialApp(
            theme: ShadTheme.darkTheme,
            home: const ExpenseFormScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open project selector and select Project B
      await tester.tap(find.text(testProjectA.name));
      await tester.pumpAndSettle();

      expect(find.text(testProjectB.name), findsOneWidget);
      await tester.tap(find.text(testProjectB.name));
      await tester.pumpAndSettle();

      // Project B should now be selected
      expect(find.text(testProjectB.name), findsOneWidget);
    });
  });

  group('D, E, F, G. ExpenseFormScreen Validation and Persistence', () {
    testWidgets('Shows error SnackBar on validation failure without crashing', (tester) async {
      configureViewport(tester);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectsListProvider.overrideWith((ref) => Future.value([testProjectA])),
            selectedProjectProvider.overrideWith((ref) => testProjectA),
            expenseCategoriesProvider.overrideWith((ref) => Future.value([testCategory])),
            recentCategoriesProvider.overrideWith((ref) => Future.value([testCategory])),
            suppliersListProvider.overrideWith((ref) => Future.value(<Supplier>[])),
          ],
          child: MaterialApp(
            theme: ShadTheme.darkTheme,
            home: const ExpenseFormScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Leave amount empty and tap Save Expense
      await tester.tap(find.text('Save Expense'));
      await tester.pumpAndSettle();

      // Should display visible validation error feedback
      expect(find.text('Please complete all required fields correctly.'), findsOneWidget);
      expect(find.text('Amount is required'), findsOneWidget);
    });

    testWidgets('Successful expense persistence records correctly and shows success feedback', (tester) async {
      configureViewport(tester);
      final successfulRepo = _MockSuccessfulExpenseRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseRepositoryProvider.overrideWithValue(successfulRepo),
            projectsListProvider.overrideWith((ref) => Future.value([testProjectA])),
            selectedProjectProvider.overrideWith((ref) => testProjectA),
            expenseCategoriesProvider.overrideWith((ref) => Future.value([testCategory])),
            recentCategoriesProvider.overrideWith((ref) => Future.value([testCategory])),
            suppliersListProvider.overrideWith((ref) => Future.value(<Supplier>[])),
          ],
          child: MaterialApp(
            theme: ShadTheme.darkTheme,
            home: const ExpenseFormScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter Amount: 45000
      final amountField = find.byType(TextFormField).first;
      await tester.enterText(amountField, '45000');
      await tester.pumpAndSettle();

      // Pick Category
      await tester.tap(find.byType(ShadCategorySelector));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cement').first);
      await tester.pumpAndSettle();

      // Tap Save Expense
      await tester.tap(find.text('Save Expense'));
      await tester.pumpAndSettle();

      // Verify repository recorded the exact values
      expect(successfulRepo.recordedExpense, isNotNull);
      expect(successfulRepo.recordedExpense!.amount.minorUnits, equals(4500000));
      expect(successfulRepo.recordedExpense!.projectId, equals(testProjectA.id));
      expect(successfulRepo.recordedExpense!.categoryId, equals(testCategory.id));
      expect(find.text('Expense saved successfully'), findsOneWidget);
    });

    testWidgets('Repository failure shows error feedback and keeps form populated for retry', (tester) async {
      configureViewport(tester);
      final failingRepo = _MockFailingExpenseRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseRepositoryProvider.overrideWithValue(failingRepo),
            projectsListProvider.overrideWith((ref) => Future.value([testProjectA])),
            selectedProjectProvider.overrideWith((ref) => testProjectA),
            expenseCategoriesProvider.overrideWith((ref) => Future.value([testCategory])),
            recentCategoriesProvider.overrideWith((ref) => Future.value([testCategory])),
            suppliersListProvider.overrideWith((ref) => Future.value(<Supplier>[])),
          ],
          child: MaterialApp(
            theme: ShadTheme.darkTheme,
            home: const ExpenseFormScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter Amount: 12500
      final amountField = find.byType(TextFormField).first;
      await tester.enterText(amountField, '12500');
      await tester.pumpAndSettle();

      // Pick Category
      await tester.tap(find.byType(ShadCategorySelector));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cement').first);
      await tester.pumpAndSettle();

      // Tap Save Expense
      await tester.tap(find.text('Save Expense'));
      await tester.pumpAndSettle();

      // Error message should be visible to user
      expect(find.textContaining('Disk write failed during transaction'), findsOneWidget);
      // Form fields should remain populated for retry
      expect(find.text('12500'), findsOneWidget);
    });
  });

  group('H. QuickExpenseScreen Fallback and Resilience', () {
    testWidgets('Saves expense using fallback project when selectedProjectProvider is temporarily null', (tester) async {
      configureViewport(tester);
      final successfulRepo = _MockSuccessfulExpenseRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseRepositoryProvider.overrideWithValue(successfulRepo),
            projectsListProvider.overrideWith((ref) => Future.value([testProjectB])),
            selectedProjectProvider.overrideWith((ref) => null), // Temporarily null
            expenseCategoriesProvider.overrideWith((ref) => Future.value([testCategory])),
            recentCategoriesProvider.overrideWith((ref) => Future.value([testCategory])),
            suppliersListProvider.overrideWith((ref) => Future.value(<Supplier>[])),
          ],
          child: MaterialApp(
            theme: ShadTheme.darkTheme,
            home: const QuickExpenseScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter amount
      final amountField = find.byType(TextFormField).first;
      await tester.enterText(amountField, '5000');
      await tester.pumpAndSettle();

      // Tap Quick category Cement
      await tester.tap(find.text('Cement').first);
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('SAVE EXPENSE NOW'));
      await tester.pumpAndSettle();

      // Should fall back to testProjectB
      expect(successfulRepo.recordedExpense, isNotNull);
      expect(successfulRepo.recordedExpense!.projectId, equals(testProjectB.id));
      expect(successfulRepo.recordedExpense!.amount.minorUnits, equals(500000));
      expect(find.text('Expense saved successfully!'), findsOneWidget);
    });
  });

  group('I. Database Category Initialization', () {
    test('Ensures categories exist when count is 0 and does not duplicate on reopen', () async {
      final db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, version) async {
            await DatabaseHelper.createSchema(db, version);
          },
        ),
      );

      final rows1 = await db.rawQuery('SELECT COUNT(*) as count FROM expense_categories');
      final count1 = rows1.first['count'] as int;
      expect(count1, greaterThan(0));

      // Re-running seedCategories is idempotent and does not duplicate
      await DatabaseHelper.seedCategories(db);
      final rows2 = await db.rawQuery('SELECT COUNT(*) as count FROM expense_categories');
      final count2 = rows2.first['count'] as int;
      expect(count2, equals(count1));

      await db.close();
    });
  });
}
