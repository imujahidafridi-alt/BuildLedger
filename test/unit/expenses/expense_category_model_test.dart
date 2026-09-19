import 'package:flutter_test/flutter_test.dart';
import 'package:build_ledger/features/expenses/data/models/expense_category_model.dart';
import 'package:build_ledger/features/expenses/domain/entities/expense_category.dart';

void main() {
  group('ExpenseCategoryModel Aliases Parsing', () {
    test('Correctly parses JSON-encoded aliases array without quotes or brackets', () {
      final map = {
        'id': 'cat_sub_site_prep',
        'parent_id': 'cat_top_site_earthwork',
        'name': 'Site Preparation',
        'code': 'SITE_PREPARATION',
        'phase': 'GREY_STRUCTURE',
        'sort_order': 1,
        'is_active': 1,
        'is_system': 1,
        'aliases': '["cleaning", "clearing", "demolition"]',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final cat = ExpenseCategoryModel.fromMap(map);
      expect(cat.aliases, equals(['cleaning', 'clearing', 'demolition']));
      expect(cat.aliases.contains('cleaning'), isTrue);
      expect(cat.aliases.any((a) => a.contains('[') || a.contains('"')), isFalse);
    });

    test('Correctly parses comma-separated aliases', () {
      final map = {
        'id': 'cat_sub_excavation',
        'parent_id': 'cat_top_site_earthwork',
        'name': 'Excavation',
        'code': 'SITE_EXCAVATION',
        'phase': 'GREY_STRUCTURE',
        'sort_order': 2,
        'is_active': 1,
        'is_system': 1,
        'aliases': 'digging, khudai, basement excavation',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final cat = ExpenseCategoryModel.fromMap(map);
      expect(cat.aliases, equals(['digging', 'khudai', 'basement excavation']));
    });

    test('Defensively cleans malformed strings with trailing brackets and escaped quotes', () {
      final map = {
        'id': 'cat_sub_test',
        'name': 'Test',
        'code': 'TEST',
        'phase': 'GREY_STRUCTURE',
        'aliases': '["malba", "debris", "dumping"]',
      };

      final cat = ExpenseCategoryModel.fromMap(map);
      expect(cat.aliases, equals(['malba', 'debris', 'dumping']));
    });

    test('Handles null, empty string, and empty array cleanly', () {
      expect(ExpenseCategoryModel.fromMap({'id': '1', 'name': 'A', 'phase': 'GREY_STRUCTURE', 'aliases': null}).aliases, isEmpty);
      expect(ExpenseCategoryModel.fromMap({'id': '2', 'name': 'B', 'phase': 'GREY_STRUCTURE', 'aliases': ''}).aliases, isEmpty);
      expect(ExpenseCategoryModel.fromMap({'id': '3', 'name': 'C', 'phase': 'GREY_STRUCTURE', 'aliases': '[]'}).aliases, isEmpty);
      expect(ExpenseCategoryModel.fromMap({'id': '4', 'name': 'D', 'phase': 'GREY_STRUCTURE', 'aliases': []}).aliases, isEmpty);
    });

    test('toMap serializes aliases as clean JSON string', () {
      final cat = ExpenseCategory(
        id: 'cat_sub_test',
        name: 'Test Subcategory',
        code: 'TEST_SUB',
        phase: CostPhase.greyStructure,
        sortOrder: 1,
        aliases: const ['cement', 'saria', 'loha'],
        createdAt: DateTime(2026, 9, 18),
        updatedAt: DateTime(2026, 9, 18),
      );

      final map = ExpenseCategoryModel.toMap(cat);
      expect(map['aliases'], equals('["cement","saria","loha"]'));
    });
  });
}
