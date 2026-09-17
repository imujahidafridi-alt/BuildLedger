import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:build_ledger/core/logging/app_logger.dart';
import 'package:build_ledger/core/database/database_factory.dart';
import 'package:build_ledger/features/expenses/data/datasources/category_seeds.dart';

/// Central database helper managing SQLite lifecycle, WAL mode, foreign keys, and migrations.
class DatabaseHelper {
  static const String _databaseName = 'build_ledger.db';
  static const int _databaseVersion = 2;

  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  /// Optional factory for test injections with in-memory or custom database instances.
  @visibleForTesting
  static void setMockDatabase(Database? db) {
    _database = db;
    _dbInitFuture = null;
  }

  static Future<Database>? _dbInitFuture;
  static bool _factoryInitialized = false;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _dbInitFuture ??= _initDatabase();
    try {
      _database = await _dbInitFuture!;
      return _database!;
    } catch (e) {
      _dbInitFuture = null;
      rethrow;
    }
  }

  Future<Database> _initDatabase() async {
    // Initialize platform database factory (Ffi on desktop/tests, FfiWeb on browser, native on mobile)
    if (!_factoryInitialized) {
      databaseFactory = getPlatformDatabaseFactory();
      _factoryInitialized = true;
    }

    String path;
    if (kIsWeb) {
      path = _databaseName;
    } else {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      path = join(documentsDirectory.path, _databaseName);
    }

    AppLogger.info('Opening SQLite database at: $path', tag: 'DatabaseHelper');

    return await openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  /// Defensive integrity check: ensures categories exist without expensive repeated work.
  Future<void> _onOpen(Database db) async {
    try {
      final rows = await db.rawQuery('SELECT COUNT(*) as count FROM expense_categories;');
      final count = rows.isNotEmpty ? (rows.first['count'] as int?) : 0;
      if (count == null || count == 0) {
        AppLogger.warning('No expense categories found on open; seeding canonical taxonomy...', tag: 'DatabaseHelper');
        await seedCategories(db);
      }
    } catch (e) {
      AppLogger.warning('Defensive category count check skipped: $e', tag: 'DatabaseHelper');
    }
  }

  /// Configures connection pragmas (Foreign keys and WAL mode)
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    // Enable Write-Ahead Logging for high concurrency and crash resilience on supported native targets.
    // Note: PRAGMA journal_mode returns a result row ('wal'), so Android SQLiteDatabase requires
    // rawQuery() instead of execute() to avoid "Queries can be performed using SQLiteDatabase query or rawQuery methods only".
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.windows) {
      try {
        await db.rawQuery('PRAGMA journal_mode = WAL;');
      } catch (e) {
        AppLogger.warning('Failed to set WAL journal mode: $e', tag: 'DatabaseHelper', error: e);
      }
    }
  }

  /// Version 1 Schema Migration
  Future<void> _onCreate(Database db, int version) async {
    await createSchema(db, version);
  }

  /// Creates schema and seeds categories. Available for test DB setup.
  @visibleForTesting
  /// Creates schema and seeds categories. Available for test DB setup.
  @visibleForTesting
  static Future<void> createSchema(Database db, [int version = _databaseVersion]) async {
    AppLogger.info('Creating SQLite tables for v$version', tag: 'DatabaseHelper');

    final batch = db.batch();

    // 1. Projects Table
    batch.execute('''
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

    // 2. Expense Categories Table
    if (version < 2) {
      batch.execute('''
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
    } else {
      batch.execute('''
        CREATE TABLE expense_categories (
          id TEXT PRIMARY KEY NOT NULL,
          parent_id TEXT REFERENCES expense_categories(id) ON DELETE RESTRICT,
          name TEXT NOT NULL,
          code TEXT NOT NULL,
          phase TEXT NOT NULL,
          icon_name TEXT,
          sort_order INTEGER NOT NULL DEFAULT 0,
          is_active INTEGER NOT NULL DEFAULT 1,
          is_system INTEGER NOT NULL DEFAULT 1,
          aliases TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          CONSTRAINT uq_category_code UNIQUE (code)
        );
      ''');
    }

    // 3. Suppliers Table
    batch.execute('''
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

    // 4. Supplier Ledger Table
    batch.execute('''
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

    // 5. Expenses Table
    batch.execute('''
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

    // 6. Labour Entries Table
    batch.execute('''
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

    // 7. Audit Logs Table
    batch.execute('''
      CREATE TABLE audit_logs (
        id TEXT PRIMARY KEY NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        action TEXT NOT NULL,
        actor TEXT NOT NULL DEFAULT 'local_user',
        payload_before TEXT,
        payload_after TEXT,
        timestamp TEXT NOT NULL
      );
    ''');

    // Performance Composite Indexes
    batch.execute('CREATE INDEX idx_expenses_project_status_date ON expenses(project_id, status, expense_date);');
    batch.execute('CREATE INDEX idx_expenses_category_status ON expenses(category_id, status);');
    batch.execute('CREATE INDEX idx_expenses_supplier_status ON expenses(supplier_id, status);');
    batch.execute('CREATE INDEX idx_supplier_ledger_supplier ON supplier_ledger(supplier_id, entry_date);');
    batch.execute('CREATE INDEX idx_labour_project_status ON labour_entries(project_id, status, entry_date);');

    if (version >= 2) {
      batch.execute('CREATE INDEX idx_expense_categories_parent ON expense_categories(parent_id);');
      batch.execute('CREATE INDEX idx_expense_categories_phase ON expense_categories(phase);');
      batch.execute('CREATE INDEX idx_expense_categories_active ON expense_categories(is_active);');
    }

    await batch.commit(noResult: true);

    // Seed Categories
    if (version < 2) {
      await _seedLegacyV1Categories(db);
    } else {
      await seedCategories(db);
    }
  }

  /// Seeds or updates canonical hierarchical categories idempotently.
  static Future<void> seedCategories(DatabaseExecutor db) async {
    final now = DateTime.now().toIso8601String();

    // Query existing IDs to determine insert vs update
    final existingRows = await db.query('expense_categories', columns: ['id']);
    final existingIds = existingRows.map((r) => r['id'] as String).toSet();

    final batch = db.batch();

    // 1. Top-Level Categories
    final topLevelSeeds = kDefaultCategoryTaxonomy.where((s) => s.parentCode == null).toList();
    final Map<String, String> codeToId = {};

    for (final seed in topLevelSeeds) {
      codeToId[seed.code] = seed.id;
      final row = {
        'id': seed.id,
        'parent_id': null,
        'name': seed.name,
        'code': seed.code,
        'phase': seed.phase.code,
        'icon_name': seed.iconName,
        'sort_order': seed.sortOrder,
        'is_active': 1,
        'is_system': 1,
        'aliases': jsonEncode(seed.aliases),
        'updated_at': now,
      };

      if (existingIds.contains(seed.id)) {
        batch.update('expense_categories', row, where: 'id = ?', whereArgs: [seed.id]);
      } else {
        row['created_at'] = now;
        batch.insert('expense_categories', row);
      }
    }

    // 2. Subcategories
    final subSeeds = kDefaultCategoryTaxonomy.where((s) => s.parentCode != null).toList();
    for (final seed in subSeeds) {
      codeToId[seed.code] = seed.id;
      final parentId = codeToId[seed.parentCode!];
      final row = {
        'id': seed.id,
        'parent_id': parentId,
        'name': seed.name,
        'code': seed.code,
        'phase': seed.phase.code,
        'icon_name': seed.iconName,
        'sort_order': seed.sortOrder,
        'is_active': 1,
        'is_system': 1,
        'aliases': jsonEncode(seed.aliases),
        'updated_at': now,
      };

      if (existingIds.contains(seed.id)) {
        batch.update('expense_categories', row, where: 'id = ?', whereArgs: [seed.id]);
      } else {
        row['created_at'] = now;
        batch.insert('expense_categories', row);
      }
    }

    await batch.commit(noResult: true);
    AppLogger.info('Seeded/verified ${kDefaultCategoryTaxonomy.length} category taxonomy items', tag: 'DatabaseHelper');
  }

  /// Seeds legacy v1 categories (used when creating a v1 test database).
  static Future<void> _seedLegacyV1Categories(Database db) async {
    final now = DateTime.now().toIso8601String();
    final categories = [
      ('cat_mat_cement', 'Cement', 'Materials', 'square_foot'),
      ('cat_mat_steel', 'Steel', 'Materials', 'hardware'),
      ('cat_mat_bricks', 'Bricks', 'Materials', 'view_module'),
      ('cat_mat_sand', 'Sand', 'Materials', 'grain'),
      ('cat_mat_crush', 'Crush / Gravel', 'Materials', 'grain'),
      ('cat_mat_blocks', 'Blocks', 'Materials', 'view_module'),
      ('cat_mat_tiles', 'Tiles', 'Materials', 'grid_view'),
      ('cat_mat_marble', 'Marble', 'Materials', 'grid_view'),
      ('cat_mat_paint', 'Paint', 'Materials', 'format_paint'),
      ('cat_mat_wood', 'Wood', 'Materials', 'carpenter'),
      ('cat_mat_glass', 'Glass', 'Materials', 'window'),
      ('cat_mat_plumbing', 'Plumbing Materials', 'Materials', 'plumbing'),
      ('cat_mat_electrical', 'Electrical Materials', 'Materials', 'electrical_services'),
      ('cat_mat_hardware', 'Hardware / Fixtures', 'Materials', 'build'),
      ('cat_lab_mason', 'Mason (Mistri)', 'Labour', 'engineering'),
      ('cat_lab_general', 'General Labour (Mazdoor)', 'Labour', 'group'),
      ('cat_lab_plumber', 'Plumber', 'Labour', 'plumbing'),
      ('cat_lab_electrician', 'Electrician', 'Labour', 'electrical_services'),
      ('cat_lab_carpenter', 'Carpenter', 'Labour', 'carpenter'),
      ('cat_lab_painter', 'Painter', 'Labour', 'format_paint'),
      ('cat_lab_welder', 'Welder', 'Labour', 'hardware'),
      ('cat_eq_excavator', 'Excavator', 'Equipment', 'precision_manufacturing'),
      ('cat_eq_mixer', 'Concrete Mixer', 'Equipment', 'sync'),
      ('cat_eq_crane', 'Crane / Hoist', 'Equipment', 'arrow_upward'),
      ('cat_eq_generator', 'Generator', 'Equipment', 'bolt'),
      ('cat_eq_tools', 'Small Tools', 'Equipment', 'construction'),
      ('cat_eq_scaffolding', 'Scaffolding', 'Equipment', 'stairs'),
      ('cat_tr_truck', 'Truck / Dumper', 'Transport', 'local_shipping'),
      ('cat_tr_loader', 'Loader / Suzuki', 'Transport', 'local_shipping'),
      ('cat_tr_delivery', 'Delivery Charges', 'Transport', 'delivery_dining'),
      ('cat_tr_fuel', 'Fuel / Diesel', 'Transport', 'local_gas_station'),
      ('cat_tr_cartage', 'Site Cartage', 'Transport', 'forklift'),
      ('cat_oth_water', 'Site Water Supply', 'Other', 'water_drop'),
      ('cat_oth_electricity', 'Temporary Electricity', 'Other', 'bolt'),
      ('cat_oth_permits', 'Official Permits / NOC', 'Other', 'description'),
      ('cat_oth_tea', 'Food / Tea (Site Catering)', 'Other', 'coffee'),
      ('cat_oth_misc', 'Miscellaneous Site Expenses', 'Other', 'more_horiz'),
    ];

    final batch = db.batch();
    for (final cat in categories) {
      batch.insert('expense_categories', {
        'id': cat.$1,
        'name': cat.$2,
        'group_name': cat.$3,
        'icon_name': cat.$4,
        'is_custom': 0,
        'created_at': now,
      });
    }
    await batch.commit(noResult: true);
  }

  /// Upgrades database from v1 to v2 (hierarchical construction expense taxonomy).
  /// Preserves all expense records, IDs, financial totals, and custom categories.
  static Future<void> upgradeToV2(Database db) async {
    AppLogger.info('Starting v1 -> v2 database migration...', tag: 'DatabaseHelper');

    // 1. Temporarily disable foreign keys and enable legacy_alter_table
    // so that ALTER TABLE RENAME does NOT rewrite references in the expenses table.
    await db.execute('PRAGMA foreign_keys = OFF;');
    await db.execute('PRAGMA legacy_alter_table = ON;');

    await db.transaction((txn) async {
      // 2. Rename existing expense_categories to legacy_expense_categories
      await txn.execute('ALTER TABLE expense_categories RENAME TO legacy_expense_categories;');

      // 3. Create target v2 expense_categories table
      await txn.execute('''
        CREATE TABLE expense_categories (
          id TEXT PRIMARY KEY NOT NULL,
          parent_id TEXT REFERENCES expense_categories(id) ON DELETE RESTRICT,
          name TEXT NOT NULL,
          code TEXT NOT NULL,
          phase TEXT NOT NULL,
          icon_name TEXT,
          sort_order INTEGER NOT NULL DEFAULT 0,
          is_active INTEGER NOT NULL DEFAULT 1,
          is_system INTEGER NOT NULL DEFAULT 1,
          aliases TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          CONSTRAINT uq_category_code UNIQUE (code)
        );
      ''');

      // 4. Performance indexes
      await txn.execute('CREATE INDEX idx_expense_categories_parent ON expense_categories(parent_id);');
      await txn.execute('CREATE INDEX idx_expense_categories_phase ON expense_categories(phase);');
      await txn.execute('CREATE INDEX idx_expense_categories_active ON expense_categories(is_active);');

      // 5. Seed the canonical taxonomy
      await seedCategories(txn);

      // 6. Migrate custom categories from legacy_expense_categories (where is_custom = 1)
      final legacyCustom = await txn.query(
        'legacy_expense_categories',
        where: 'is_custom = 1',
      );
      final now = DateTime.now().toIso8601String();
      for (final cat in legacyCustom) {
        final id = cat['id'] as String;
        final name = cat['name'] as String;
        final iconName = cat['icon_name'] as String?;
        final createdAt = (cat['created_at'] as String?) ?? now;
        final groupName = (cat['group_name'] as String?) ?? 'Other';

        String phaseCode = 'professional_site';
        if (groupName.toLowerCase().contains('material') ||
            groupName.toLowerCase().contains('labour') ||
            groupName.toLowerCase().contains('structure')) {
          phaseCode = 'grey_structure';
        } else if (groupName.toLowerCase().contains('finish')) {
          phaseCode = 'finishing';
        } else if (groupName.toLowerCase().contains('external')) {
          phaseCode = 'external_works';
        }

        final cleanCode = 'CUSTOM_${id.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_').toUpperCase()}';

        await txn.insert('expense_categories', {
          'id': id,
          'parent_id': null,
          'name': name,
          'code': cleanCode,
          'phase': phaseCode,
          'icon_name': iconName,
          'sort_order': 999,
          'is_active': 1,
          'is_system': 0,
          'aliases': '[]',
          'created_at': createdAt,
          'updated_at': now,
        });
      }

      // 7. Remap any expenses pointing to legacy IDs that changed
      for (final entry in kLegacyCategoryMapping.entries) {
        if (entry.key != entry.value) {
          await txn.update(
            'expenses',
            {'category_id': entry.value},
            where: 'category_id = ?',
            whereArgs: [entry.key],
          );
        }
      }

      // 8. Foreign key validation check
      final fkViolations = await txn.rawQuery('PRAGMA foreign_key_check;');
      if (fkViolations.isNotEmpty) {
        throw StateError('Foreign key check failed during v2 migration: $fkViolations');
      }

      // 9. Drop temporary legacy table
      await txn.execute('DROP TABLE legacy_expense_categories;');
    });

    // 10. Re-enable foreign keys and reset legacy_alter_table
    await db.execute('PRAGMA legacy_alter_table = OFF;');
    await db.execute('PRAGMA foreign_keys = ON;');
    AppLogger.info('Successfully migrated database to v2', tag: 'DatabaseHelper');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    AppLogger.info('Upgrading database from $oldVersion to $newVersion', tag: 'DatabaseHelper');
    if (oldVersion < 2) {
      await upgradeToV2(db);
    }
  }

  /// Closes database connection safely.
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }
}
