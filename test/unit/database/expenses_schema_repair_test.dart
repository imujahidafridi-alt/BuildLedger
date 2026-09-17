import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:build_ledger/core/database/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('repairExpensesSchemaIfNeeded detects corrupted legacy_expense_categories reference and heals table', () async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await DatabaseHelper.createSchema(db, 2);
          await DatabaseHelper.seedCategories(db);
        },
      ),
    );

    // Simulate SQLite table rename side-effect:
    // Create legacy_expense_categories and simulate corrupted expenses definition
    await db.execute('PRAGMA foreign_keys = OFF;');
    await db.execute('''
      CREATE TABLE legacy_expense_categories (
        id TEXT PRIMARY KEY,
        name TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE expenses_corrupted (
        id TEXT PRIMARY KEY NOT NULL,
        project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE RESTRICT,
        category_id TEXT NOT NULL REFERENCES legacy_expense_categories(id) ON DELETE RESTRICT,
        supplier_id TEXT REFERENCES suppliers(id) ON DELETE RESTRICT,
        amount_minor INTEGER NOT NULL,
        payment_method TEXT NOT NULL,
        expense_date TEXT NOT NULL,
        description TEXT,
        receipt_path TEXT,
        status TEXT NOT NULL DEFAULT 'active',
        voided_at TEXT,
        void_reason TEXT,
        voided_by TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'local',
        server_version INTEGER NOT NULL DEFAULT 1
      );
    ''');
    await db.execute('DROP TABLE expenses;');
    await db.execute('ALTER TABLE expenses_corrupted RENAME TO expenses;');
    await db.execute('DROP TABLE legacy_expense_categories;');
    await db.execute('PRAGMA foreign_keys = ON;');

    // Verify the corruption is present in sqlite_master
    final schemaRows = await db.rawQuery("SELECT sql FROM sqlite_master WHERE type = 'table' AND name = 'expenses';");
    final sql = schemaRows.first['sql'] as String;
    expect(sql.contains('legacy_expense_categories'), true);

    // Run the repair
    await DatabaseHelper.repairExpensesSchemaIfNeeded(db);

    // Verify repaired table references expense_categories, not legacy_expense_categories
    final repairedRows = await db.rawQuery("SELECT sql FROM sqlite_master WHERE type = 'table' AND name = 'expenses';");
    final repairedSql = repairedRows.first['sql'] as String;
    expect(repairedSql.contains('legacy_expense_categories'), false);
    expect(repairedSql.contains('expense_categories'), true);

    // Insert a project and then insert an expense to verify compilation and execution succeed!
    final now = DateTime.now().toIso8601String();
    await db.insert('projects', {
      'id': 'proj-test',
      'name': 'Test Project',
      'budget_amount': 1000000,
      'status': 'active',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('expenses', {
      'id': 'exp-test',
      'project_id': 'proj-test',
      'category_id': 'cat_top_site_earthwork',
      'amount_minor': 50000,
      'payment_method': 'cash',
      'expense_date': now,
      'description': 'Test Expense',
      'created_at': now,
      'updated_at': now,
    });

    final expenses = await db.query('expenses', where: 'id = ?', whereArgs: ['exp-test']);
    expect(expenses.length, 1);
    expect(expenses.first['description'], 'Test Expense');

    await db.close();
  });
}
