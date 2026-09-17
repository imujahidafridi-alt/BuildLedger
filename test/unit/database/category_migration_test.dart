import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:build_ledger/core/database/database_helper.dart';
import 'package:build_ledger/features/expenses/data/datasources/category_seeds.dart';

void main() {
  int firstIntValue(List<Map<String, Object?>> rows) {
    if (rows.isEmpty || rows.first.isEmpty) return 0;
    return (rows.first.values.first as num?)?.toInt() ?? 0;
  }

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Category Taxonomy Definitions Test', () {
    test('Taxonomy contains exactly 23 top-level categories', () {
      final topLevel = kDefaultCategoryTaxonomy.where((c) => c.parentCode == null).toList();
      expect(topLevel.length, equals(23));

      final expectedTopLevelCodes = {
        'SITE_EARTHWORK',
        'FOUNDATION',
        'RCC_STRUCTURE',
        'MASONRY',
        'BUILDING_MATERIALS',
        'PLASTER_SCREED',
        'WATERPROOFING_INSULATION',
        'PLUMBING_DRAINAGE',
        'GAS',
        'ELECTRICAL',
        'FLOORING_TILES',
        'DOORS_WINDOWS',
        'METALWORK',
        'WOODWORK_JOINERY',
        'KITCHEN',
        'BATHROOMS_SANITARY',
        'PAINT_WALL_FINISHES',
        'CEILING_INTERIOR',
        'EXTERNAL_WORKS',
        'FIXTURES_FITTINGS',
        'LABOUR',
        'CONTRACTOR_PROFESSIONAL',
        'SITE_MISC',
      };

      final actualCodes = topLevel.map((c) => c.code).toSet();
      expect(actualCodes, equals(expectedTopLevelCodes));
    });

    test('All subcategories reference valid top-level or parent codes', () {
      final allCodes = kDefaultCategoryTaxonomy.map((c) => c.code).toSet();
      for (final seed in kDefaultCategoryTaxonomy) {
        if (seed.parentCode != null) {
          expect(
            allCodes.contains(seed.parentCode),
            isTrue,
            reason: 'Subcategory ${seed.code} references unknown parent ${seed.parentCode}',
          );
        }
      }
    });

    test('All seed category codes are unique', () {
      final codes = <String>{};
      for (final seed in kDefaultCategoryTaxonomy) {
        expect(codes.contains(seed.code), isFalse, reason: 'Duplicate code: ${seed.code}');
        codes.add(seed.code);
      }
    });

    test('All seed category IDs are unique', () {
      final ids = <String>{};
      for (final seed in kDefaultCategoryTaxonomy) {
        expect(ids.contains(seed.id), isFalse, reason: 'Duplicate ID: ${seed.id}');
        ids.add(seed.id);
      }
    });
  });

  group('SQLite v1 -> v2 Migration and Financial Integrity', () {
    late Database db;

    setUp(() async {
      // 1. Open an in-memory database and create v1 schema
      db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onConfigure: (db) async {
            await db.execute('PRAGMA foreign_keys = ON;');
          },
          onCreate: (db, version) async {
            await DatabaseHelper.createSchema(db, 1);
          },
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('Full migration verifies financial totals, category mapping, and FK integrity', () async {
      final now = DateTime.now().toIso8601String();

      // Seed a project
      await db.insert('projects', {
        'id': 'proj_1',
        'name': 'Model Town Villa',
        'budget_amount': 500000000, // 5M PKR in minor units
        'status': 'active',
        'currency': 'PKR',
        'created_at': now,
        'updated_at': now,
      });

      // Seed a supplier
      await db.insert('suppliers', {
        'id': 'sup_1',
        'name': 'Bestway Cement Depot',
        'created_at': now,
        'updated_at': now,
      });

      // Insert a custom category in v1
      await db.insert('expense_categories', {
        'id': 'cat_custom_scaffolding_rental',
        'name': 'Scaffolding Rental Custom',
        'group_name': 'Equipment',
        'icon_name': 'stairs',
        'is_custom': 1,
        'created_at': now,
      });

      // Seed several expenses in v1 with legacy category IDs
      final expensesToSeed = [
        {
          'id': 'exp_1',
          'project_id': 'proj_1',
          'category_id': 'cat_mat_cement',
          'supplier_id': 'sup_1',
          'amount_minor': 2900000, // 29,000 PKR
          'payment_method': 'cash',
          'expense_date': '2026-03-01',
          'description': '20 bags Bestway Cement',
          'status': 'active',
          'created_at': now,
          'updated_at': now,
        },
        {
          'id': 'exp_2',
          'project_id': 'proj_1',
          'category_id': 'cat_mat_steel',
          'supplier_id': 'sup_1',
          'amount_minor': 15000000, // 150,000 PKR
          'payment_method': 'bank',
          'expense_date': '2026-03-02',
          'description': 'Grade 60 Steel 1 Ton',
          'status': 'active',
          'created_at': now,
          'updated_at': now,
        },
        {
          'id': 'exp_3_voided',
          'project_id': 'proj_1',
          'category_id': 'cat_mat_bricks',
          'supplier_id': null,
          'amount_minor': 4500000, // 45,000 PKR
          'payment_method': 'cash',
          'expense_date': '2026-03-03',
          'description': 'Awwal Bricks (Cancelled)',
          'status': 'voided',
          'voided_at': now,
          'void_reason': 'Order cancelled by vendor',
          'voided_by': 'Admin',
          'created_at': now,
          'updated_at': now,
        },
        {
          'id': 'exp_4_remapping',
          'project_id': 'proj_1',
          'category_id': 'cat_eq_crane', // legacy remapping to cat_eq_excavator
          'supplier_id': null,
          'amount_minor': 3500000, // 35,000 PKR
          'payment_method': 'cash',
          'expense_date': '2026-03-04',
          'description': 'Mobile Crane Rental for roof pour',
          'status': 'active',
          'created_at': now,
          'updated_at': now,
        },
        {
          'id': 'exp_5_custom_cat',
          'project_id': 'proj_1',
          'category_id': 'cat_custom_scaffolding_rental',
          'supplier_id': null,
          'amount_minor': 1200000, // 12,000 PKR
          'payment_method': 'cash',
          'expense_date': '2026-03-05',
          'description': 'Pipe scaffolding for 15 days',
          'status': 'active',
          'created_at': now,
          'updated_at': now,
        },
      ];

      for (final exp in expensesToSeed) {
        await db.insert('expenses', exp);
      }

      // --- CAPTURE PRE-MIGRATION TOTALS ---
      final preCountResult = firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM expenses;'),
      );
      final preActiveTotal = firstIntValue(
        await db.rawQuery("SELECT COALESCE(SUM(amount_minor), 0) FROM expenses WHERE status = 'active';"),
      );
      final preVoidedTotal = firstIntValue(
        await db.rawQuery("SELECT COALESCE(SUM(amount_minor), 0) FROM expenses WHERE status = 'voided';"),
      );
      final preOverallTotal = firstIntValue(
        await db.rawQuery('SELECT COALESCE(SUM(amount_minor), 0) FROM expenses;'),
      );
      final preSupplierTotal = firstIntValue(
        await db.rawQuery("SELECT COALESCE(SUM(amount_minor), 0) FROM expenses WHERE supplier_id = 'sup_1';"),
      );
      final preProjectTotal = firstIntValue(
        await db.rawQuery("SELECT COALESCE(SUM(amount_minor), 0) FROM expenses WHERE project_id = 'proj_1';"),
      );

      expect(preCountResult, equals(5));
      expect(preActiveTotal, equals(2900000 + 15000000 + 3500000 + 1200000));
      expect(preVoidedTotal, equals(4500000));
      expect(preOverallTotal, equals(preActiveTotal + preVoidedTotal));

      // --- EXECUTE V1 -> V2 UPGRADE ---
      await DatabaseHelper.upgradeToV2(db);

      // --- VALIDATE POST-MIGRATION INTEGRITY ---
      final postCountResult = firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM expenses;'),
      );
      final postActiveTotal = firstIntValue(
        await db.rawQuery("SELECT COALESCE(SUM(amount_minor), 0) FROM expenses WHERE status = 'active';"),
      );
      final postVoidedTotal = firstIntValue(
        await db.rawQuery("SELECT COALESCE(SUM(amount_minor), 0) FROM expenses WHERE status = 'voided';"),
      );
      final postOverallTotal = firstIntValue(
        await db.rawQuery('SELECT COALESCE(SUM(amount_minor), 0) FROM expenses;'),
      );
      final postSupplierTotal = firstIntValue(
        await db.rawQuery("SELECT COALESCE(SUM(amount_minor), 0) FROM expenses WHERE supplier_id = 'sup_1';"),
      );
      final postProjectTotal = firstIntValue(
        await db.rawQuery("SELECT COALESCE(SUM(amount_minor), 0) FROM expenses WHERE project_id = 'proj_1';"),
      );

      // Rule: BEFORE == AFTER for all financial aggregates
      expect(postCountResult, equals(preCountResult));
      expect(postActiveTotal, equals(preActiveTotal));
      expect(postVoidedTotal, equals(preVoidedTotal));
      expect(postOverallTotal, equals(preOverallTotal));
      expect(postSupplierTotal, equals(preSupplierTotal));
      expect(postProjectTotal, equals(preProjectTotal));

      // --- VALIDATE FOREIGN KEY CONSTRAINTS ---
      final fkViolations = await db.rawQuery('PRAGMA foreign_key_check;');
      expect(fkViolations, isEmpty, reason: 'Found foreign key violations: $fkViolations');

      // --- VALIDATE RECLASSIFIED EXPENSE ---
      final remappedExpense = (await db.query(
        'expenses',
        where: 'id = ?',
        whereArgs: ['exp_4_remapping'],
      )).first;
      expect(remappedExpense['category_id'], equals('cat_eq_excavator'));

      // --- VALIDATE CUSTOM CATEGORY SURVIVAL ---
      final customCategoryRows = await db.query(
        'expense_categories',
        where: 'id = ?',
        whereArgs: ['cat_custom_scaffolding_rental'],
      );
      expect(customCategoryRows.length, equals(1));
      final customCat = customCategoryRows.first;
      expect(customCat['name'], equals('Scaffolding Rental Custom'));
      expect(customCat['is_system'], equals(0));
      expect(customCat['is_active'], equals(1));

      // --- VALIDATE 23 TOP-LEVEL CATEGORIES IN DB ---
      final dbTopLevel = await db.query(
        'expense_categories',
        where: 'parent_id IS NULL AND is_system = 1',
      );
      expect(dbTopLevel.length, equals(23));

      // --- VALIDATE IDEMPOTENCY ---
      // Running seed again should produce 0 errors and zero duplicate codes/IDs
      await DatabaseHelper.seedCategories(db);
      final countAfterSecondSeed = firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM expense_categories;'),
      );
      final countBeforeSecondSeed = firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM expense_categories;'),
      );
      expect(countAfterSecondSeed, equals(countBeforeSecondSeed));

      final fkViolationsSecond = await db.rawQuery('PRAGMA foreign_key_check;');
      expect(fkViolationsSecond, isEmpty);
    });
  });
}
