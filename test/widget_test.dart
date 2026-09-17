import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:build_ledger/app/app.dart';
import 'package:build_ledger/features/projects/presentation/controllers/project_controller.dart';
import 'package:build_ledger/features/projects/domain/entities/project.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('BuildLedgerApp renders navigation bar and dashboard smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectsListProvider.overrideWith((ref) => Future.value(<Project>[])),
        ],
        child: const BuildLedgerApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify app bar brand title
    expect(find.text('BuildLedger'), findsOneWidget);

    // Verify Navigation bar destinations
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Projects'), findsWidgets);
    expect(find.text('Expenses'), findsWidgets);
    expect(find.text('Reports'), findsWidgets);
    expect(find.text('More'), findsWidgets);
  });
}
