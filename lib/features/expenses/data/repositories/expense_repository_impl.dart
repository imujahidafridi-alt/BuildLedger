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
        conditions.add("e.category_id = ?");
        args.add(categoryId);
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
          c.group_name as group_name,
          s.name as supplier_name,
          p.name as project_name
        FROM expenses e
        JOIN expense_categories c ON e.category_id = c.id
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
  Future<Result<List<ExpenseCategory>>> getCategories() async {
    try {
      final db = await _dbHelper.database;
      final rows = await db.query('expense_categories', orderBy: 'group_name ASC, name ASC');
      final list = rows.map(ExpenseCategoryModel.fromMap).toList();
      return Result.success(list);
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to fetch categories: $e'));
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
          c.group_name as group_name,
          s.name as supplier_name,
          p.name as project_name
        FROM expenses e
        JOIN expense_categories c ON e.category_id = c.id
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
