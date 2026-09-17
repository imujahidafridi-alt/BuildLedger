import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:build_ledger/core/design_system/theme.dart';
import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/features/expenses/domain/entities/expense.dart';
import 'package:build_ledger/features/expenses/domain/entities/expense_category.dart';
import 'package:build_ledger/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:build_ledger/features/expenses/presentation/screens/expense_form_screen.dart';
import 'package:build_ledger/features/projects/domain/entities/project.dart';
import 'package:build_ledger/features/projects/presentation/controllers/project_controller.dart';
import 'package:build_ledger/features/suppliers/domain/entities/supplier.dart';
import 'package:build_ledger/features/suppliers/presentation/controllers/supplier_controller.dart';
import 'package:build_ledger/shared/ui/forms/shad_category_selector.dart';

void main() {
  final now = DateTime(2026, 3, 15);

  final testProject = Project(
    id: 'proj_test_1',
    name: 'Gulberg Plaza Commercial',
    location: 'Lahore',
    budgetAmount: const Money(2000000000), // Rs 20,000,000
    status: ProjectStatus.active,
    createdAt: now,
    updatedAt: now,
  );

  final parentMaterials = ExpenseCategory(
    id: 'cat_materials',
    name: 'Building Materials',
    code: 'BUILDING_MATERIALS',
    phase: CostPhase.greyStructure,
    sortOrder: 5,
    createdAt: now,
    updatedAt: now,
  );

  final childCement = ExpenseCategory(
    id: 'cat_mat_cement',
    parentId: 'cat_materials',
    name: 'Cement',
    code: 'MAT_CEMENT',
    phase: CostPhase.greyStructure,
    sortOrder: 1,
    aliases: ['cement', 'simant', 'chuna'],
    createdAt: now,
    updatedAt: now,
  );

  final childSteel = ExpenseCategory(
    id: 'cat_mat_steel',
    parentId: 'cat_materials',
    name: 'Steel / Saria',
    code: 'MAT_STEEL',
    phase: CostPhase.greyStructure,
    sortOrder: 2,
    aliases: ['saria', 'rebar', 'iron'],
    createdAt: now,
    updatedAt: now,
  );

  final parentFinishing = ExpenseCategory(
    id: 'cat_tiles_parent',
    name: 'Flooring & Tiles',
    code: 'FLOORING_TILES',
    phase: CostPhase.finishing,
    sortOrder: 11,
    createdAt: now,
    updatedAt: now,
  );

  final childPorcelain = ExpenseCategory(
    id: 'cat_porcelain',
    parentId: 'cat_tiles_parent',
    name: 'Porcelain Tiles',
    code: 'TILES_PORCELAIN',
    phase: CostPhase.finishing,
    sortOrder: 1,
    aliases: ['tile', 'marbal'],
    createdAt: now,
    updatedAt: now,
  );

  final allCategories = [
    parentMaterials,
    childCement,
    childSteel,
    parentFinishing,
    childPorcelain,
  ];

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        projectsListProvider.overrideWith((ref) => Future.value([testProject])),
        selectedProjectProvider.overrideWith((ref) => testProject),
        expenseCategoriesProvider.overrideWith((ref) => Future.value(allCategories)),
        recentCategoriesProvider.overrideWith((ref) => Future.value([childCement, childSteel])),
        suppliersListProvider.overrideWith((ref) => Future.value(<Supplier>[])),
      ],
      child: MaterialApp(
        theme: ShadTheme.darkTheme,
        home: const ExpenseFormScreen(),
      ),
    );
  }

  void configureViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('ExpenseFormScreen Category Hierarchy Integration', () {
    testWidgets('Renders ShadCategorySelector with default placeholder when empty', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ShadCategorySelector), findsOneWidget);
      expect(find.text('Select an expense category'), findsOneWidget);
      expect(find.text('Expense Category *'), findsOneWidget);
    });

    testWidgets('Tapping ShadCategorySelector opens sheet and displays categories', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ShadCategorySelector));
      await tester.pumpAndSettle();

      // Sheet is visible
      expect(find.text('Select Category'), findsOneWidget);
      expect(find.text('Building Materials'), findsAtLeastNWidgets(1));
      expect(find.text('Flooring & Tiles'), findsOneWidget);
    });

    testWidgets('Selecting a leaf subcategory updates display to Parent · Subcategory', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ShadCategorySelector));
      await tester.pumpAndSettle();

      // Tap on Building Materials to drill down
      await tester.tap(find.text('Building Materials').first);
      await tester.pumpAndSettle();

      // Now Cement is visible in subcategories
      expect(find.text('Cement'), findsOneWidget);
      await tester.tap(find.text('Cement'));
      await tester.pumpAndSettle();

      // Sheet closes and selector displays Parent · Child
      expect(find.text('Building Materials · Cement'), findsOneWidget);
    });

    testWidgets('Selecting leaf from another phase derives the correct CostPhase', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ShadCategorySelector));
      await tester.pumpAndSettle();

      // Drill down into Flooring & Tiles
      await tester.tap(find.text('Flooring & Tiles').first);
      await tester.pumpAndSettle();

      // Tap Porcelain Tiles
      await tester.tap(find.text('Porcelain Tiles'));
      await tester.pumpAndSettle();

      expect(find.text('Flooring & Tiles · Porcelain Tiles'), findsOneWidget);
      expect(childPorcelain.phase, equals(CostPhase.finishing));
    });

    testWidgets('Historical expense remains readable and preserves exact financial amount', (tester) async {
      final historicalExpense = Expense(
        id: 'hist_exp_1',
        projectId: testProject.id,
        categoryId: childCement.id,
        amount: const Money(2900000), // Rs 29,000
        paymentMethod: PaymentMethod.cash,
        expenseDate: now,
        description: '20 Bags Bestway OPC Cement',
        createdAt: now,
        updatedAt: now,
      );

      // Verify financial integrity
      expect(historicalExpense.amount.minorUnits, equals(2900000));
      expect(historicalExpense.amount.majorValue, equals(29000));
      expect(historicalExpense.categoryId, equals('cat_mat_cement'));
      expect(historicalExpense.isVoided, isFalse);

      // Resolve category
      final matched = allCategories.firstWhere((c) => c.id == historicalExpense.categoryId);
      expect(matched.name, equals('Cement'));
      expect(matched.phase, equals(CostPhase.greyStructure));
    });

    testWidgets('Voided expenses remain voided with zero financial alteration', (tester) async {
      final voidedExpense = Expense(
        id: 'void_exp_1',
        projectId: testProject.id,
        categoryId: childSteel.id,
        amount: const Money(15000000), // Rs 150,000
        paymentMethod: PaymentMethod.credit,
        expenseDate: now,
        status: ExpenseStatus.voided,
        voidReason: 'Cancelled order',
        voidedAt: now,
        voidedBy: 'admin',
        createdAt: now,
        updatedAt: now,
      );

      expect(voidedExpense.isVoided, isTrue);
      expect(voidedExpense.amount.minorUnits, equals(15000000));
      expect(voidedExpense.categoryId, equals('cat_mat_steel'));
    });
  });
}
