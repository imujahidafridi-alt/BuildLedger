import 'package:uuid/uuid.dart';
import 'package:build_ledger/core/database/database_helper.dart';
import 'package:build_ledger/core/database/transaction_runner.dart';
import 'package:build_ledger/core/domain/result.dart';
import 'package:build_ledger/core/errors/app_failure.dart';
import 'package:build_ledger/features/expenses/domain/entities/expense.dart';
import 'package:build_ledger/features/expenses/domain/entities/expense_category.dart';
import 'package:build_ledger/features/expenses/domain/repositories/expense_repository.dart';
import 'package:build_ledger/features/expenses/data/models/expense_model.dart';
import 'package:build_ledger/features/expenses/data/models/expense_category_model.dart';
import 'package:build_ledger/features/suppliers/data/models/supplier_ledger_model.dart';
import 'package:build_ledger/features/suppliers/domain/entities/supplier_ledger_entry.dart';
import 'package:build_ledger/features/receipts/data/datasources/receipt_storage_service.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final DatabaseHelper _dbHelper;
  final TransactionRunner _transactionRunner;
  final ReceiptStorageService _receiptService;

  ExpenseRepositoryImpl({
    DatabaseHelper? dbHelper,
    TransactionRunner? transactionRunner,
    ReceiptStorageService? receiptService,
  })  : _dbHelper = dbHelper ?? DatabaseHelper(),
        _transactionRunner = transactionRunner ?? TransactionRunner(),
        _receiptService = receiptService ?? ReceiptStorageService();

  @override
  Future<Result<Expense>> recordExpense(Expense expense, {String? stagedReceiptPath}) async {
    try {
      final now = DateTime.now();

      // Execute atomic multi-table database transaction
      await _transactionRunner.run((txn) async {
        // 1. Insert into expenses
        await txn.insert('expenses', ExpenseModel.toMap(expense));

        // 2. If purchase is on credit, atomically record to supplier ledger
        if (expense.isCredit && expense.supplierId != null) {
          final ledgerEntry = SupplierLedgerEntry(
            id: const Uuid().v4(),
            supplierId: expense.supplierId!,
            projectId: expense.projectId,
            direction: LedgerDirection.credit, // Credit increases supplier liability
            entryType: LedgerEntryType.purchase,
            amount: expense.amount,
            referenceId: expense.id,
            description: expense.description ?? 'Material Purchase on Credit',
            entryDate: expense.expenseDate,
            createdAt: now,
          );
          await txn.insert('supplier_ledger', SupplierLedgerModel.toMap(ledgerEntry));
        }

        // 3. Write immutable audit log
        await txn.insert('audit_logs', {
          'id': const Uuid().v4(),
          'entity_type': 'expense',
          'entity_id': expense.id,
          'action': 'create',
          'actor': 'local_user',
          'payload_before': null,
          'payload_after': '${expense.amount.minorUnits} (${expense.paymentMethod.name})',
          'timestamp': now.toIso8601String(),
        });
      });

      // Two-Phase File Promotion: Promote staged file only after DB commit succeeds
      var finalExpense = expense;
      if (stagedReceiptPath != null) {
        final permanentPath = await _receiptService.promoteReceipt(
          stagedPath: stagedReceiptPath,
          projectId: expense.projectId,
          expenseId: expense.id,
        );

        final db = await _dbHelper.database;
        await db.update(
          'expenses',
          {'receipt_path': permanentPath},
          where: 'id = ?',
          whereArgs: [expense.id],
        );
        finalExpense = expense.copyWith(receiptPath: permanentPath);
      }

      return Result.success(finalExpense);
    } catch (e) {
      // Clean up orphan temporary receipt on failure
      if (stagedReceiptPath != null) {
        await _receiptService.discardStagedReceipt(stagedReceiptPath);
      }
      return Result.failure(DatabaseFailure('Failed to record expense: $e'));
    }
  }

  @override
  Future<Result<Expense>> updateExpense(Expense expense, {String? stagedReceiptPath}) async {
    try {
      final now = DateTime.now();

      await _transactionRunner.run((txn) async {
        // 1. Fetch existing expense to compare changes
        final rows = await txn.query(
          'expenses',
          where: 'id = ?',
          whereArgs: [expense.id],
          limit: 1,
        );
        if (rows.isEmpty) throw Exception('Expense record not found');
        final oldExpense = ExpenseModel.fromMap(rows.first);

        // 2. Reconcile supplier ledger if credit status or supplier or amount changed
        if (oldExpense.isCredit && oldExpense.supplierId != null) {
          await txn.delete(
            'supplier_ledger',
            where: 'reference_id = ? AND entry_type = ?',
            whereArgs: [expense.id, LedgerEntryType.purchase.toDbString()],
          );
        }

        if (expense.isCredit && expense.supplierId != null && expense.isActive) {
          final ledgerEntry = SupplierLedgerEntry(
            id: const Uuid().v4(),
            supplierId: expense.supplierId!,
            projectId: expense.projectId,
            direction: LedgerDirection.credit,
            entryType: LedgerEntryType.purchase,
            amount: expense.amount,
            referenceId: expense.id,
            description: expense.description ?? 'Material Purchase on Credit',
            entryDate: expense.expenseDate,
            createdAt: now,
          );
          await txn.insert('supplier_ledger', SupplierLedgerModel.toMap(ledgerEntry));
        }

        // 3. Update expenses table
        final updatedExpense = expense.copyWith(updatedAt: now);
        await txn.update(
          'expenses',
          ExpenseModel.toMap(updatedExpense),
          where: 'id = ?',
          whereArgs: [expense.id],
        );

        // 4. Insert audit log
        await txn.insert('audit_logs', {
          'id': const Uuid().v4(),
          'entity_type': 'expense',
          'entity_id': expense.id,
          'action': 'update',
          'actor': 'local_user',
          'payload_before': 'amount: ${oldExpense.amount.minorUnits}, cat: ${oldExpense.categoryId}',
          'payload_after': 'amount: ${expense.amount.minorUnits}, cat: ${expense.categoryId}',
          'timestamp': now.toIso8601String(),
        });
      });

      // Two-phase promotion if new receipt provided
      var finalExpense = expense;
      if (stagedReceiptPath != null) {
        final permanentPath = await _receiptService.promoteReceipt(
          stagedPath: stagedReceiptPath,
          projectId: expense.projectId,
          expenseId: expense.id,
        );

        final db = await _dbHelper.database;
        await db.update(
          'expenses',
          {'receipt_path': permanentPath},
          where: 'id = ?',
          whereArgs: [expense.id],
        );
        finalExpense = expense.copyWith(receiptPath: permanentPath);
      }

      return Result.success(finalExpense);
    } catch (e) {
      if (stagedReceiptPath != null) {
        await _receiptService.discardStagedReceipt(stagedReceiptPath);
      }
      return Result.failure(DatabaseFailure('Failed to update expense: $e'));
    }
  }

  @override
  Future<Result<void>> deleteExpense(String expenseId) async {
    try {
      final now = DateTime.now();

      await _transactionRunner.run((txn) async {
        // 1. Fetch existing expense
        final rows = await txn.query(
          'expenses',
          where: 'id = ?',
          whereArgs: [expenseId],
          limit: 1,
        );
        if (rows.isEmpty) throw Exception('Expense record not found');
        final expense = ExpenseModel.fromMap(rows.first);

        // 2. Clean up any supplier ledger entries referencing this expense
        await txn.delete(
          'supplier_ledger',
          where: 'reference_id = ?',
          whereArgs: [expenseId],
        );

        // 3. Delete expense record
        await txn.delete(
          'expenses',
          where: 'id = ?',
          whereArgs: [expenseId],
        );

        // 4. Audit log
        await txn.insert('audit_logs', {
          'id': const Uuid().v4(),
          'entity_type': 'expense',
          'entity_id': expenseId,
          'action': 'delete',
          'actor': 'local_user',
          'payload_before': 'amount: ${expense.amount.minorUnits}, desc: ${expense.description}',
          'payload_after': null,
          'timestamp': now.toIso8601String(),
        });
      });

      return const Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to delete expense: $e'));
    }
  }

  @override
  Future<Result<void>> voidExpense({
    required String expenseId,
    required String reason,
    required String actor,
  }) async {
    try {
      final now = DateTime.now();

      await _transactionRunner.run((txn) async {
        // 1. Fetch original record
        final rows = await txn.query(
          'expenses',
          where: 'id = ?',
          whereArgs: [expenseId],
          limit: 1,
        );
        if (rows.isEmpty) throw Exception('Expense record not found');
        final expense = ExpenseModel.fromMap(rows.first);

        if (expense.isVoided) {
          throw Exception('Expense is already voided');
        }

        // 2. Void the expense record (preserving original data for audit)
        await txn.update(
          'expenses',
          {
            'status': 'voided',
            'voided_at': now.toIso8601String(),
            'void_reason': reason,
            'voided_by': actor,
            'updated_at': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [expenseId],
        );

        // 3. If it was a credit transaction, insert a compensating reversal into the supplier ledger
        if (expense.isCredit && expense.supplierId != null) {
          final reversalEntry = SupplierLedgerEntry(
            id: const Uuid().v4(),
            supplierId: expense.supplierId!,
            projectId: expense.projectId,
            direction: LedgerDirection.debit, // Debit reverses the credit liability
            entryType: LedgerEntryType.adjustment,
            amount: expense.amount,
            referenceId: expense.id,
            description: 'Voided Expense Reversal: $reason',
            entryDate: now,
            createdAt: now,
          );
          await txn.insert('supplier_ledger', SupplierLedgerModel.toMap(reversalEntry));
        }

        // 4. Log audit record
        await txn.insert('audit_logs', {
          'id': const Uuid().v4(),
          'entity_type': 'expense',
          'entity_id': expenseId,
          'action': 'void',
          'actor': actor,
          'payload_before': 'amount: ${expense.amount.minorUnits}',
          'payload_after': 'reason: $reason',
          'timestamp': now.toIso8601String(),
        });
      });

      return const Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to void expense: $e'));
    }
  }

  @override
  Future<Result<List<Expense>>> getExpenses({
    String? projectId,
    String? categoryId,
    CostPhase? phase,
    String? supplierId,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    bool includeVoided = false,
  }) async {
    try {
      final db = await _dbHelper.database;
      final conditions = <String>[];
      final args = <dynamic>[];

      if (!includeVoided) {
        conditions.add("e.status = 'active'");
      }
      if (projectId != null) {
        conditions.add("e.project_id = ?");
        args.add(projectId);
      }
      if (categoryId != null) {
        // Matches exact category ID or any subcategory under this parent
        conditions.add("(e.category_id = ? OR c.parent_id = ?)");
        args.add(categoryId);
        args.add(categoryId);
      }
      if (phase != null) {
        conditions.add("c.phase = ?");
        args.add(phase.code);
      }
      if (supplierId != null) {
        conditions.add("e.supplier_id = ?");
        args.add(supplierId);
      }
      if (startDate != null) {
        conditions.add("e.expense_date >= ?");
        args.add(startDate.toIso8601String());
      }
      if (endDate != null) {
        conditions.add("e.expense_date <= ?");
        args.add(endDate.toIso8601String());
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        conditions.add("(e.description LIKE ? OR c.name LIKE ? OR s.name LIKE ?)");
        final q = '%${searchQuery.trim()}%';
        args.addAll([q, q, q]);
      }

      final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';

      final sql = '''
        SELECT 
          e.*,
          c.name as category_name,
          parent.name as parent_category_name,
          c.phase as phase,
          COALESCE(parent.name, c.name) as group_name,
          s.name as supplier_name,
          p.name as project_name
        FROM expenses e
        JOIN expense_categories c ON e.category_id = c.id
        LEFT JOIN expense_categories parent ON c.parent_id = parent.id
        LEFT JOIN suppliers s ON e.supplier_id = s.id
        JOIN projects p ON e.project_id = p.id
        $whereClause
        ORDER BY e.expense_date DESC, e.created_at DESC
      ''';

      final rows = await db.rawQuery(sql, args);
      final list = rows.map(ExpenseModel.fromMap).toList();
      return Result.success(list);
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to fetch expenses: $e'));
    }
  }

  @override
  Future<Result<List<ExpenseCategory>>> getCategories({bool activeOnly = true}) async {
    try {
      final db = await _dbHelper.database;
      final rows = await db.query(
        'expense_categories',
        where: activeOnly ? 'is_active = 1' : null,
        orderBy: 'sort_order ASC, name ASC',
      );
      final list = rows.map(ExpenseCategoryModel.fromMap).toList();
      return Result.success(list);
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to fetch categories: $e'));
    }
  }

  @override
  Future<Result<List<ExpenseCategory>>> getCategoriesByPhase(CostPhase phase, {bool activeOnly = true}) async {
    try {
      final db = await _dbHelper.database;
      final rows = await db.query(
        'expense_categories',
        where: activeOnly ? 'phase = ? AND is_active = 1' : 'phase = ?',
        whereArgs: [phase.code],
        orderBy: 'sort_order ASC, name ASC',
      );
      final list = rows.map(ExpenseCategoryModel.fromMap).toList();
      return Result.success(list);
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to fetch categories by phase: $e'));
    }
  }

  @override
  Future<Result<List<ExpenseCategory>>> getTopLevelCategories({CostPhase? phase, bool activeOnly = true}) async {
    try {
      final db = await _dbHelper.database;
      final conditions = <String>['parent_id IS NULL'];
      final args = <dynamic>[];

      if (activeOnly) {
        conditions.add('is_active = 1');
      }
      if (phase != null) {
        conditions.add('phase = ?');
        args.add(phase.code);
      }

      final rows = await db.query(
        'expense_categories',
        where: conditions.join(' AND '),
        whereArgs: args.isNotEmpty ? args : null,
        orderBy: 'sort_order ASC, name ASC',
      );
      final list = rows.map(ExpenseCategoryModel.fromMap).toList();
      return Result.success(list);
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to fetch top-level categories: $e'));
    }
  }

  @override
  Future<Result<List<ExpenseCategory>>> getSubcategories(String parentId, {bool activeOnly = true}) async {
    try {
      final db = await _dbHelper.database;
      final rows = await db.query(
        'expense_categories',
        where: activeOnly ? 'parent_id = ? AND is_active = 1' : 'parent_id = ?',
        whereArgs: [parentId],
        orderBy: 'sort_order ASC, name ASC',
      );
      final list = rows.map(ExpenseCategoryModel.fromMap).toList();
      return Result.success(list);
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to fetch subcategories: $e'));
    }
  }

  @override
  Future<Result<List<ExpenseCategory>>> searchCategories(
    String query, {
    CostPhase? phase,
    bool activeOnly = true,
  }) async {
    try {
      final normalizedQuery = _normalize(query);
      if (normalizedQuery.isEmpty) {
        return getCategories(activeOnly: activeOnly);
      }

      final db = await _dbHelper.database;
      final rows = await db.query(
        'expense_categories',
        where: activeOnly ? 'is_active = 1' : null,
        orderBy: 'sort_order ASC, name ASC',
      );
      final allCategories = rows.map(ExpenseCategoryModel.fromMap).toList();

      final categoryMap = {for (final c in allCategories) c.id: c};
      final scoredCategories = <_CategoryMatch>[];

      for (final cat in allCategories) {
        if (phase != null && cat.phase != phase) continue;

        final parentName = cat.parentId != null ? categoryMap[cat.parentId]?.name : null;
        final normName = _normalize(cat.name);
        final normParent = parentName != null ? _normalize(parentName) : '';
        final normCode = _normalize(cat.code);

        int score = 0;

        // Exact match on name
        if (normName == normalizedQuery) {
          score = 100;
        }
        // Exact match on any alias
        else if (cat.aliases.any((a) => _normalize(a) == normalizedQuery)) {
          score = 95;
        }
        // Name starts with query
        else if (normName.startsWith(normalizedQuery)) {
          score = 85;
        }
        // Alias starts with query
        else if (cat.aliases.any((a) => _normalize(a).startsWith(normalizedQuery))) {
          score = 80;
        }
        // Name contains query
        else if (normName.contains(normalizedQuery)) {
          score = 70;
        }
        // Alias contains query
        else if (cat.aliases.any((a) => _normalize(a).contains(normalizedQuery))) {
          score = 65;
        }
        // Parent category contains query
        else if (normParent.isNotEmpty && normParent.contains(normalizedQuery)) {
          score = 50;
        }
        // Code contains query
        else if (normCode.contains(normalizedQuery)) {
          score = 40;
        }

        if (score > 0) {
          scoredCategories.add(_CategoryMatch(cat, score));
        }
      }

      scoredCategories.sort((a, b) {
        if (b.score != a.score) return b.score.compareTo(a.score);
        return a.category.sortOrder.compareTo(b.category.sortOrder);
      });

      return Result.success(scoredCategories.map((m) => m.category).toList());
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to search categories: $e'));
    }
  }

  static String _normalize(String s) {
    return s.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  @override
  Future<Result<List<ExpenseCategory>>> getRecentCategories({String? projectId, int limit = 6}) async {
    try {
      final db = await _dbHelper.database;
      final args = <dynamic>[];
      var projectFilter = '';
      if (projectId != null) {
        projectFilter = 'AND e.project_id = ?';
        args.add(projectId);
      }
      args.add(limit);

      final sql = '''
        SELECT c.*
        FROM expense_categories c
        JOIN (
          SELECT e.category_id, MAX(e.expense_date) as last_used
          FROM expenses e
          WHERE e.status = 'active' $projectFilter
          GROUP BY e.category_id
          ORDER BY last_used DESC
          LIMIT ?
        ) r ON c.id = r.category_id
        WHERE c.is_active = 1
        ORDER BY r.last_used DESC
      ''';

      final rows = await db.rawQuery(sql, args);
      final recent = rows.map(ExpenseCategoryModel.fromMap).toList();

      if (recent.length < limit) {
        final existingIds = recent.map((c) => c.id).toSet();
        const fallbackIds = [
          'cat_mat_cement',
          'cat_mat_steel',
          'cat_mat_bricks',
          'cat_mat_sand',
          'cat_lab_general',
          'cat_mat_plumbing',
        ];

        for (final fbId in fallbackIds) {
          if (recent.length >= limit) break;
          if (!existingIds.contains(fbId)) {
            final fbRows = await db.query(
              'expense_categories',
              where: 'id = ? AND is_active = 1',
              whereArgs: [fbId],
            );
            if (fbRows.isNotEmpty) {
              recent.add(ExpenseCategoryModel.fromMap(fbRows.first));
              existingIds.add(fbId);
            }
          }
        }
      }

      return Result.success(recent);
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to fetch recent categories: $e'));
    }
  }

  @override
  Future<Result<List<ExpenseCategory>>> getFrequentCategories({String? projectId, int limit = 6}) async {
    try {
      final db = await _dbHelper.database;
      final args = <dynamic>[];
      var projectFilter = '';
      if (projectId != null) {
        projectFilter = 'AND e.project_id = ?';
        args.add(projectId);
      }
      args.add(limit);

      final sql = '''
        SELECT c.*
        FROM expense_categories c
        JOIN (
          SELECT e.category_id, COUNT(*) as usage_count
          FROM expenses e
          WHERE e.status = 'active' $projectFilter
          GROUP BY e.category_id
          ORDER BY usage_count DESC
          LIMIT ?
        ) f ON c.id = f.category_id
        WHERE c.is_active = 1
        ORDER BY f.usage_count DESC
      ''';

      final rows = await db.rawQuery(sql, args);
      final frequent = rows.map(ExpenseCategoryModel.fromMap).toList();

      if (frequent.length < limit) {
        final existingIds = frequent.map((c) => c.id).toSet();
        const fallbackIds = [
          'cat_mat_cement',
          'cat_mat_steel',
          'cat_mat_bricks',
          'cat_mat_sand',
          'cat_lab_general',
          'cat_mat_plumbing',
        ];

        for (final fbId in fallbackIds) {
          if (frequent.length >= limit) break;
          if (!existingIds.contains(fbId)) {
            final fbRows = await db.query(
              'expense_categories',
              where: 'id = ? AND is_active = 1',
              whereArgs: [fbId],
            );
            if (fbRows.isNotEmpty) {
              frequent.add(ExpenseCategoryModel.fromMap(fbRows.first));
              existingIds.add(fbId);
            }
          }
        }
      }

      return Result.success(frequent);
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to fetch frequent categories: $e'));
    }
  }

  @override
  Future<Result<ExpenseCategory>> createCustomCategory({
    required String name,
    required CostPhase phase,
    String? parentId,
    String? iconName,
  }) async {
    try {
      final trimmedName = name.trim();
      if (trimmedName.isEmpty) {
        return const Result.failure(ValidationFailure('Category name cannot be empty.'));
      }

      final db = await _dbHelper.database;
      // Check duplicate name under same parent
      final dupRows = await db.query(
        'expense_categories',
        where: parentId != null ? 'LOWER(name) = ? AND parent_id = ?' : 'LOWER(name) = ? AND parent_id IS NULL',
        whereArgs: parentId != null ? [trimmedName.toLowerCase(), parentId] : [trimmedName.toLowerCase()],
      );
      if (dupRows.isNotEmpty) {
        return const Result.failure(ValidationFailure('A category with this name already exists here.'));
      }

      final id = const Uuid().v4();
      final sanitized = trimmedName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toUpperCase();
      final code = 'CUSTOM_${sanitized}_${DateTime.now().millisecondsSinceEpoch % 10000}';
      final now = DateTime.now();

      final category = ExpenseCategory(
        id: id,
        parentId: parentId,
        name: trimmedName,
        code: code,
        phase: phase,
        iconName: iconName ?? 'folder',
        sortOrder: 999,
        isActive: true,
        isSystem: false,
        aliases: const [],
        createdAt: now,
        updatedAt: now,
      );

      await db.insert('expense_categories', ExpenseCategoryModel.toMap(category));
      return Result.success(category);
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to create custom category: $e'));
    }
  }

  @override
  Future<Result<void>> toggleCategoryActive({
    required String categoryId,
    required bool isActive,
  }) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now().toIso8601String();
      await db.transaction((txn) async {
        await txn.update(
          'expense_categories',
          {'is_active': isActive ? 1 : 0, 'updated_at': now},
          where: 'id = ?',
          whereArgs: [categoryId],
        );

        // If deactivating a parent category, also deactivate its subcategories
        if (!isActive) {
          await txn.update(
            'expense_categories',
            {'is_active': 0, 'updated_at': now},
            where: 'parent_id = ?',
            whereArgs: [categoryId],
          );
        }
      });
      return const Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to toggle category active status: $e'));
    }
  }

  @override
  Future<Result<void>> updateCustomCategory({
    required String categoryId,
    required String name,
    String? iconName,
  }) async {
    try {
      final trimmedName = name.trim();
      if (trimmedName.isEmpty) {
        return const Result.failure(ValidationFailure('Category name cannot be empty.'));
      }

      final db = await _dbHelper.database;
      final checkRows = await db.query(
        'expense_categories',
        where: 'id = ?',
        whereArgs: [categoryId],
      );
      if (checkRows.isEmpty) {
        return const Result.failure(NotFoundFailure('Category not found.'));
      }
      if (checkRows.first['is_system'] == 1) {
        return const Result.failure(ValidationFailure('System categories cannot be renamed.'));
      }

      final updates = <String, dynamic>{
        'name': trimmedName,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (iconName != null) {
        updates['icon_name'] = iconName;
      }

      await db.update('expense_categories', updates, where: 'id = ?', whereArgs: [categoryId]);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to update category: $e'));
    }
  }

  @override
  Future<Result<Expense?>> getExpenseById(String id) async {
    try {
      final db = await _dbHelper.database;
      final sql = '''
        SELECT 
          e.*,
          c.name as category_name,
          parent.name as parent_category_name,
          c.phase as phase,
          COALESCE(parent.name, c.name) as group_name,
          s.name as supplier_name,
          p.name as project_name
        FROM expenses e
        JOIN expense_categories c ON e.category_id = c.id
        LEFT JOIN expense_categories parent ON c.parent_id = parent.id
        LEFT JOIN suppliers s ON e.supplier_id = s.id
        JOIN projects p ON e.project_id = p.id
        WHERE e.id = ?
        LIMIT 1
      ''';
      final rows = await db.rawQuery(sql, [id]);
      if (rows.isEmpty) return const Result.success(null);
      return Result.success(ExpenseModel.fromMap(rows.first));
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to fetch expense: $e'));
    }
  }
}

class _CategoryMatch {
  final ExpenseCategory category;
  final int score;
  _CategoryMatch(this.category, this.score);
}
