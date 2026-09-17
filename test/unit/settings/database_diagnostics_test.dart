import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:build_ledger/core/database/database_helper.dart';
import 'package:build_ledger/features/settings/data/database_diagnostics_service.dart';

void main() {
  late Database db;
  late DatabaseHelper dbHelper;
  late DatabaseDiagnosticsService diagnosticsService;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await DatabaseHelper.createSchema(db);
    DatabaseHelper.setMockDatabase(db);
    dbHelper = DatabaseHelper();
    diagnosticsService = DatabaseDiagnosticsService(dbHelper: dbHelper);
  });

  tearDown(() async {
    DatabaseHelper.setMockDatabase(null);
    await db.close();
  });

  group('DatabaseDiagnosticsService Tests', () {
    test('Queries database statistics and record counts correctly', () async {
      final diag = await diagnosticsService.getDiagnostics();

      expect(diag.sqliteVersion, isNotEmpty);
      expect(diag.projectCount, equals(0));
      expect(diag.expenseCount, equals(0));
      expect(diag.supplierCount, equals(0));
      expect(diag.labourCount, equals(0));
      expect(diag.categoryCount, greaterThan(0)); // Seeded categories
      expect(diag.formattedSize, isNotEmpty);
      expect(diag.totalRecords, equals(diag.categoryCount));
    });

    test('Executes VACUUM optimization safely without error', () async {
      await expectLater(diagnosticsService.optimizeDatabase(), completes);
    });
  });
}
