import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:build_ledger/core/database/database_helper.dart';
import 'package:build_ledger/core/database/transaction_runner.dart';

void main() {
  late Database db;
  late TransactionRunner transactionRunner;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // In-memory test database
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          // invoke onCreate directly
          await db.execute('''
            CREATE TABLE projects (
              id TEXT PRIMARY KEY NOT NULL,
              name TEXT NOT NULL,
              description TEXT,
              client_name TEXT,
              location TEXT,
              budget_amount INTEGER NOT NULL DEFAULT 0,
              start_date TEXT,
              expected_end_date TEXT,
              status TEXT NOT NULL DEFAULT 'active',
              currency TEXT NOT NULL DEFAULT 'PKR',
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              archived_at TEXT,
              sync_status TEXT NOT NULL DEFAULT 'local',
              server_version INTEGER NOT NULL DEFAULT 1,
              CONSTRAINT chk_project_budget CHECK (budget_amount >= 0),
              CONSTRAINT chk_project_status CHECK (status IN ('active', 'completed', 'archived'))
            );
          ''');

          await db.execute('''
            CREATE TABLE expense_categories (
              id TEXT PRIMARY KEY NOT NULL,
              name TEXT NOT NULL,
              group_name TEXT NOT NULL,
              icon_name TEXT,
              is_custom INTEGER NOT NULL DEFAULT 0,
              created_at TEXT NOT NULL,
              CONSTRAINT uq_category_name_group UNIQUE (name, group_name)
            );
          ''');

          await db.execute('''
            CREATE TABLE suppliers (
              id TEXT PRIMARY KEY NOT NULL,
              name TEXT NOT NULL,
              phone TEXT,
              address TEXT,
              notes TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              archived_at TEXT,
              sync_status TEXT NOT NULL DEFAULT 'local',
              CONSTRAINT uq_supplier_name UNIQUE (name)
            );
          ''');

          await db.execute('''
            CREATE TABLE supplier_ledger (
              id TEXT PRIMARY KEY NOT NULL,
              supplier_id TEXT NOT NULL REFERENCES suppliers(id) ON DELETE RESTRICT,
              project_id TEXT REFERENCES projects(id) ON DELETE RESTRICT,
              direction TEXT NOT NULL,
              entry_type TEXT NOT NULL,
              amount_minor INTEGER NOT NULL,
              reference_id TEXT,
              description TEXT NOT NULL,
              entry_date TEXT NOT NULL,
              created_at TEXT NOT NULL,
              sync_status TEXT NOT NULL DEFAULT 'local',
              CONSTRAINT chk_ledger_amount CHECK (amount_minor > 0),
              CONSTRAINT chk_ledger_direction CHECK (direction IN ('credit', 'debit')),
              CONSTRAINT chk_ledger_type CHECK (entry_type IN ('opening_balance', 'purchase', 'payment', 'adjustment', 'refund'))
            );
          ''');

          await db.execute('''
            CREATE TABLE expenses (
              id TEXT PRIMARY KEY NOT NULL,
              project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE RESTRICT,
              category_id TEXT NOT NULL REFERENCES expense_categories(id) ON DELETE RESTRICT,
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
              server_version INTEGER NOT NULL DEFAULT 1,
              CONSTRAINT chk_expense_amount CHECK (amount_minor > 0),
              CONSTRAINT chk_expense_status CHECK (status IN ('active', 'voided')),
              CONSTRAINT chk_expense_void_consistency CHECK (
                (status = 'active' AND voided_at IS NULL AND void_reason IS NULL) OR
                (status = 'voided' AND voided_at IS NOT NULL AND void_reason IS NOT NULL)
              )
            );
          ''');

          await db.execute('''
            CREATE TABLE labour_entries (
              id TEXT PRIMARY KEY NOT NULL,
              project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE RESTRICT,
              worker_name TEXT NOT NULL,
              role TEXT NOT NULL,
              rate_minor INTEGER NOT NULL,
              days_x100 INTEGER NOT NULL DEFAULT 100,
              advance_minor INTEGER NOT NULL DEFAULT 0,
              net_amount_minor INTEGER NOT NULL,
              entry_date TEXT NOT NULL,
              status TEXT NOT NULL DEFAULT 'active',
              voided_at TEXT,
              void_reason TEXT,
              notes TEXT,
              expense_id TEXT REFERENCES expenses(id) ON DELETE SET NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              CONSTRAINT chk_labour_rate CHECK (rate_minor >= 0),
              CONSTRAINT chk_labour_days CHECK (days_x100 > 0),
              CONSTRAINT chk_labour_advance CHECK (advance_minor >= 0),
              CONSTRAINT chk_labour_net CHECK (net_amount_minor >= 0),
              CONSTRAINT chk_labour_status CHECK (status IN ('active', 'voided'))
            );
          ''');
        },
      ),
    );
    DatabaseHelper.setMockDatabase(db);
    transactionRunner = TransactionRunner();
  });

  tearDown(() async {
    await db.close();
    DatabaseHelper.setMockDatabase(null);
  });

  group('Database Schema & Integrity Constraints', () {
    test('enforces foreign key restrictions on expenses', () async {
      expect(
        () async => await db.insert('expenses', {
          'id': 'exp_1',
          'project_id': 'non_existent_project',
          'category_id': 'cat_1',
          'amount_minor': 500000,
          'payment_method': 'cash',
          'expense_date': '2026-09-17',
          'status': 'active',
          'created_at': '2026-09-17T11:00:00',
          'updated_at': '2026-09-17T11:00:00',
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('enforces check constraints on budget and amounts', () async {
      // Negative budget constraint
      expect(
        () async => await db.insert('projects', {
          'id': 'proj_neg',
          'name': 'Invalid Project',
          'budget_amount': -500,
          'status': 'active',
          'created_at': '2026-09-17T11:00:00',
          'updated_at': '2026-09-17T11:00:00',
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('enforces expense void consistency constraint', () async {
      // 1. Insert valid project and category
      await db.insert('projects', {
        'id': 'proj_1',
        'name': 'Project Alpha',
        'budget_amount': 100000000,
        'status': 'active',
        'created_at': '2026-09-17T11:00:00',
        'updated_at': '2026-09-17T11:00:00',
      });

      await db.insert('expense_categories', {
        'id': 'cat_cement',
        'name': 'Cement',
        'group_name': 'Materials',
        'created_at': '2026-09-17T11:00:00',
      });

      // 2. Active expense with void fields must fail
      expect(
        () async => await db.insert('expenses', {
          'id': 'exp_inconsistent_1',
          'project_id': 'proj_1',
          'category_id': 'cat_cement',
          'amount_minor': 2500000,
          'payment_method': 'cash',
          'expense_date': '2026-09-17',
          'status': 'active',
          'voided_at': '2026-09-17T12:00:00', // Invalid: active cannot have voided_at
          'void_reason': 'Accidental duplicate',
          'created_at': '2026-09-17T11:00:00',
          'updated_at': '2026-09-17T11:00:00',
        }),
        throwsA(isA<DatabaseException>()),
      );

      // 3. Voided expense WITHOUT void reason must fail
      expect(
        () async => await db.insert('expenses', {
          'id': 'exp_inconsistent_2',
          'project_id': 'proj_1',
          'category_id': 'cat_cement',
          'amount_minor': 2500000,
          'payment_method': 'cash',
          'expense_date': '2026-09-17',
          'status': 'voided',
          'voided_at': '2026-09-17T12:00:00',
          'void_reason': null, // Invalid: must have reason
          'created_at': '2026-09-17T11:00:00',
          'updated_at': '2026-09-17T11:00:00',
        }),
        throwsA(isA<DatabaseException>()),
      );

      // 4. Valid active expense succeeds
      await db.insert('expenses', {
        'id': 'exp_valid',
        'project_id': 'proj_1',
        'category_id': 'cat_cement',
        'amount_minor': 2500000,
        'payment_method': 'cash',
        'expense_date': '2026-09-17',
        'status': 'active',
        'created_at': '2026-09-17T11:00:00',
        'updated_at': '2026-09-17T11:00:00',
      });

      final rows = await db.query('expenses', where: 'id = ?', whereArgs: ['exp_valid']);
      expect(rows.length, equals(1));
      expect(rows.first['amount_minor'], equals(2500000));
    });

    test('TransactionRunner rolls back atomically on exception', () async {
      await db.insert('projects', {
        'id': 'proj_tx',
        'name': 'Tx Test Project',
        'budget_amount': 50000000,
        'status': 'active',
        'created_at': '2026-09-17T11:00:00',
        'updated_at': '2026-09-17T11:00:00',
      });

      try {
        await transactionRunner.run((txn) async {
          await txn.insert('suppliers', {
            'id': 'sup_tx',
            'name': 'Test Supplier',
            'created_at': '2026-09-17T11:00:00',
            'updated_at': '2026-09-17T11:00:00',
          });

          // Simulate intentional error mid-transaction
          throw Exception('Simulated crash during multi-table update');
        });
      } catch (_) {}

      // Supplier should NOT exist due to rollback
      final check = await db.query('suppliers', where: 'id = ?', whereArgs: ['sup_tx']);
      expect(check, isEmpty);
    });
  });
}
