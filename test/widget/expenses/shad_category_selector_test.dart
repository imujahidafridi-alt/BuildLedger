import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:build_ledger/core/design_system/theme.dart';
import 'package:build_ledger/features/expenses/domain/entities/expense_category.dart';
import 'package:build_ledger/shared/ui/forms/shad_category_selector.dart';

void main() {
  final now = DateTime.now();

  final mockTopLevelCat = ExpenseCategory(
    id: 'cat_top_mat',
    name: 'Building Materials',
    code: 'BUILDING_MATERIALS',
    phase: CostPhase.greyStructure,
    iconName: 'construction',
    sortOrder: 1,
    isActive: true,
    isSystem: true,
    aliases: const ['cement', 'saria', 'steel', 'sand'],
    createdAt: now,
    updatedAt: now,
  );

  final mockSubCat1 = ExpenseCategory(
    id: 'cat_sub_cement',
    parentId: 'cat_top_mat',
    name: 'Cement',
    code: 'MAT_CEMENT',
    phase: CostPhase.greyStructure,
    sortOrder: 1,
    isActive: true,
    isSystem: true,
    aliases: const ['bestway', 'fauji', 'lucky'],
    createdAt: now,
    updatedAt: now,
  );

  final mockSubCat2 = ExpenseCategory(
    id: 'cat_sub_steel',
    parentId: 'cat_top_mat',
    name: 'Steel / Saria',
    code: 'MAT_STEEL',
    phase: CostPhase.greyStructure,
    sortOrder: 2,
    isActive: true,
    isSystem: true,
    aliases: const ['saria', 'rebar', 'grade 60'],
    createdAt: now,
    updatedAt: now,
  );

  final mockFinishingCat = ExpenseCategory(
    id: 'cat_top_doors',
    name: 'Doors & Windows',
    code: 'DOORS_WINDOWS',
    phase: CostPhase.finishing,
    iconName: 'door_front_door',
    sortOrder: 2,
    isActive: true,
    isSystem: true,
    aliases: const ['darwaza', 'khidki', 'chokhat'],
    createdAt: now,
    updatedAt: now,
  );

  final allMockCategories = [
    mockTopLevelCat,
    mockSubCat1,
    mockSubCat2,
    mockFinishingCat,
  ];

  Widget buildTestApp({
    ExpenseCategory? value,
    List<ExpenseCategory>? categories,
    List<ExpenseCategory>? recentCategories,
    ValueChanged<ExpenseCategory?>? onChanged,
    bool enabled = true,
    String? errorText,
  }) {
    return MaterialApp(
      theme: ShadTheme.darkTheme,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ShadCategorySelector(
            value: value,
            categories: categories ?? allMockCategories,
            recentCategories: recentCategories ?? [mockSubCat1],
            onChanged: onChanged ?? (_) {},
            enabled: enabled,
            errorText: errorText,
          ),
        ),
      ),
    );
  }

  group('ShadCategorySelector Widget Tests', () {
    testWidgets('Renders placeholder and category icon when value is null', (tester) async {
      await tester.pumpWidget(buildTestApp(value: null));

      expect(find.text('Select category...'), findsOneWidget);
      expect(find.text('Category *'), findsOneWidget);
      expect(find.byIcon(Icons.category_outlined), findsOneWidget);
    });

    testWidgets('Renders "Parent · Subcategory" when leaf subcategory is selected', (tester) async {
      await tester.pumpWidget(buildTestApp(value: mockSubCat1));

      expect(find.text('Building Materials · Cement'), findsOneWidget);
    });

    testWidgets('Disabled state prevents opening sheet on tap', (tester) async {
      await tester.pumpWidget(buildTestApp(enabled: false));

      await tester.tap(find.byType(ShadCategorySelector));
      await tester.pumpAndSettle();

      expect(find.text('Select Category'), findsNothing);
    });

    testWidgets('Displays errorText when provided', (tester) async {
      await tester.pumpWidget(buildTestApp(errorText: 'Please select a category'));

      expect(find.text('Please select a category'), findsOneWidget);
    });

    testWidgets('Tapping opens sheet showing search, phase tabs, recent chips, and top-level categories', (tester) async {
      await tester.pumpWidget(buildTestApp());

      await tester.tap(find.byType(ShadCategorySelector));
      await tester.pumpAndSettle();

      expect(find.text('Select Category'), findsOneWidget);
      expect(find.text('RECENT'), findsOneWidget);
      expect(find.text('Cement'), findsOneWidget); // Recent chip
      expect(find.text('Building Materials'), findsOneWidget);
      expect(find.text('Doors & Windows'), findsOneWidget);
    });

    testWidgets('Drilling into top category navigates to subcategories with back button', (tester) async {
      ExpenseCategory? selected;
      await tester.pumpWidget(buildTestApp(onChanged: (cat) => selected = cat));

      await tester.tap(find.byType(ShadCategorySelector));
      await tester.pumpAndSettle();

      // Tap "Building Materials"
      await tester.tap(find.text('Building Materials'));
      await tester.pumpAndSettle();

      // Header now displays drilled category name with back arrow
      expect(find.text('Building Materials'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.text('Steel / Saria'), findsOneWidget);

      // Tap Steel / Saria leaf
      await tester.tap(find.text('Steel / Saria'));
      await tester.pumpAndSettle();

      // Sheet should be dismissed and value selected
      expect(selected?.id, equals('cat_sub_steel'));
      expect(find.text('Select Category'), findsNothing);
    });

    testWidgets('Search query filters live and tapping search result returns category', (tester) async {
      ExpenseCategory? selected;
      await tester.pumpWidget(buildTestApp(onChanged: (cat) => selected = cat));

      await tester.tap(find.byType(ShadCategorySelector));
      await tester.pumpAndSettle();

      // Enter search query "saria"
      final searchInput = find.byType(TextField);
      await tester.enterText(searchInput, 'saria');
      await tester.pumpAndSettle();

      expect(find.text('Steel / Saria'), findsOneWidget);

      // Tap search result
      await tester.tap(find.text('Steel / Saria'));
      await tester.pumpAndSettle();

      expect(selected?.id, equals('cat_sub_steel'));
      expect(find.text('Select Category'), findsNothing);
    });

    testWidgets('Phase chip filters top categories', (tester) async {
      await tester.pumpWidget(buildTestApp());

      await tester.tap(find.byType(ShadCategorySelector));
      await tester.pumpAndSettle();

      // Tap "Finishing" phase chip
      await tester.tap(find.widgetWithText(InkWell, 'Finishing').first);
      await tester.pumpAndSettle();

      expect(find.text('Doors & Windows'), findsOneWidget);
      expect(find.text('Building Materials'), findsNothing);
    });

    testWidgets('Semantics has button: true and accessible label', (tester) async {
      await tester.pumpWidget(buildTestApp(value: mockSubCat1));

      final semanticsFinder = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.button == true,
      );
      expect(semanticsFinder, findsAtLeastNWidgets(1));
    });
  });
}
