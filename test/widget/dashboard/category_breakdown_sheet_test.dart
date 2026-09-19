import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:build_ledger/app/theme/app_theme.dart';
import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/features/dashboard/presentation/widgets/category_spend_card.dart';
import 'package:build_ledger/features/dashboard/presentation/widgets/category_breakdown_sheet.dart';

void main() {
  testWidgets('CategorySpendCard renders View Breakdown button and opens sheet', (tester) async {
    final breakdown = {
      'Materials': Money.fromMajor(1500),
      'Labour': Money.fromMajor(800),
      'Finishing': Money.fromMajor(400),
    };

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: CategorySpendCard(
            categoryBreakdown: breakdown,
            projectName: 'Villa Construction',
          ),
        ),
      ),
    );

    expect(find.text('TOP EXPENSE CATEGORIES'), findsOneWidget);
    expect(find.text('View Breakdown'), findsOneWidget);

    // Tap View Breakdown header button
    await tester.tap(find.text('View Breakdown'));
    await tester.pumpAndSettle();

    // Verify sheet opened
    expect(find.text('Category Cost Breakdown'), findsOneWidget);
    expect(find.text('TOTAL EXPENDITURE'), findsOneWidget);
    expect(find.text('3 CATEGORIES'), findsOneWidget);
    expect(find.text('View All Expenses'), findsOneWidget);

    // Dismiss sheet
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Verify sheet closed
    expect(find.text('Category Cost Breakdown'), findsNothing);

    // Now test tapping a category row
    await tester.tap(find.text('Materials'));
    await tester.pumpAndSettle();
    expect(find.text('Category Cost Breakdown'), findsOneWidget);

    // Dismiss again
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Category Cost Breakdown'), findsNothing);
  });

  testWidgets('CategoryBreakdownSheet shows empty state when breakdown is empty', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                CategoryBreakdownSheet.show(
                  context,
                  breakdown: {},
                  projectName: 'New Project',
                );
              },
              child: const Text('Open Empty'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Empty'));
    await tester.pumpAndSettle();

    expect(find.text('No Expense Categories Recorded'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });
}
