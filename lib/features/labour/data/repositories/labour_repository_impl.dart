import 'package:uuid/uuid.dart';
import 'package:build_ledger/core/database/database_helper.dart';
import 'package:build_ledger/core/database/transaction_runner.dart';
import 'package:build_ledger/core/domain/result.dart';
import 'package:build_ledger/core/errors/app_failure.dart';
import 'package:build_ledger/features/labour/domain/entities/labour_entry.dart';
import 'package:build_ledger/features/labour/domain/repositories/labour_repository.dart';
import 'package:build_ledger/features/labour/data/models/labour_model.dart';
import 'package:build_ledger/features/expenses/data/models/expense_model.dart';
import 'package:build_ledger/features/expenses/domain/entities/expense.dart';

class LabourRepositoryImpl implements LabourRepository {
  final DatabaseHelper _dbHelper;
  final TransactionRunner _transactionRunner;

  LabourRepositoryImpl({
    DatabaseHelper? dbHelper,
    TransactionRunner? transactionRunner,
  })  : _dbHelper = dbHelper ?? DatabaseHelper(),
        _transactionRunner = transactionRunner ?? TransactionRunner();

  @override
  Future<Result<LabourEntry>> recordLabourShift(LabourEntry entry, {bool autoCreateProjectExpense = false}) async {
    try {
      final now = DateTime.now();

      await _transactionRunner.run((txn) async {
        String? linkedExpenseId;

        // Optionally create an expense entry automatically for site cash labour payouts
        if (autoCreateProjectExpense && entry.netAmount.isPositive) {
          linkedExpenseId = const Uuid().v4();
          final expense = Expense(
            id: linkedExpenseId,
            projectId: entry.projectId,
            categoryId: 'cat_lab_general',
            amount: entry.netAmount,
            paymentMethod: PaymentMethod.cash,
            expenseDate: entry.entryDate,
            description: 'Labour Payout: ${entry.workerName} (${entry.role})',
            createdAt: now,
            updatedAt: now,
          );
          await txn.insert('expenses', ExpenseModel.toMap(expense));
        }

        final entryToInsert = LabourEntry(
          id: entry.id,
          projectId: entry.projectId,
          workerName: entry.workerName,
          role: entry.role,
          rate: entry.rate,
          daysX100: entry.daysX100,
          advance: entry.advance,
          netAmount: entry.netAmount,
          entryDate: entry.entryDate,
          notes: entry.notes,
          expenseId: linkedExpenseId,
          createdAt: now,
          updatedAt: now,
        );

        await txn.insert('labour_entries', LabourModel.toMap(entryToInsert));

        await txn.insert('audit_logs', {
          'id': const Uuid().v4(),
          'entity_type': 'labour',
          'entity_id': entry.id,
          'action': 'create',
          'actor': 'local_user',
          'payload_before': null,
          'payload_after': '${entry.workerName} - ${entry.netAmount.minorUnits}',
          'timestamp': now.toIso8601String(),
        });
      });

      return Result.success(entry);
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to record labour shift: $e'));
    }
  }

  @override
  Future<Result<void>> voidLabourShift({
    required String labourId,
    required String reason,
    required String actor,
  }) async {
    try {
      final now = DateTime.now();

      await _transactionRunner.run((txn) async {
        final rows = await txn.query('labour_entries', where: 'id = ?', whereArgs: [labourId], limit: 1);
        if (rows.isEmpty) throw Exception('Labour shift not found');
        final entry = LabourModel.fromMap(rows.first);

        if (entry.isVoided) throw Exception('Labour shift already voided');

        // Void the labour record
        await txn.update(
          'labour_entries',
          {
            'status': 'voided',
            'voided_at': now.toIso8601String(),
            'void_reason': reason,
            'updated_at': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [labourId],
        );

        // If a linked expense was generated, void the expense too!
        if (entry.expenseId != null) {
          await txn.update(
            'expenses',
            {
              'status': 'voided',
              'voided_at': now.toIso8601String(),
              'void_reason': 'Linked labour record voided: $reason',
              'voided_by': actor,
              'updated_at': now.toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [entry.expenseId],
          );
        }

        await txn.insert('audit_logs', {
          'id': const Uuid().v4(),
          'entity_type': 'labour',
          'entity_id': labourId,
          'action': 'void',
          'actor': actor,
          'payload_before': null,
          'payload_after': reason,
          'timestamp': now.toIso8601String(),
        });
      });

      return const Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to void labour shift: $e'));
    }
  }

  @override
  Future<Result<List<LabourEntry>>> getLabourEntries({
    String? projectId,
    DateTime? startDate,
    DateTime? endDate,
    bool includeVoided = false,
  }) async {
    try {
      final db = await _dbHelper.database;
      final conditions = <String>[];
      final args = <dynamic>[];

      if (!includeVoided) {
        conditions.add("l.status = 'active'");
      }
      if (projectId != null) {
        conditions.add("l.project_id = ?");
        args.add(projectId);
      }
      if (startDate != null) {
        conditions.add("l.entry_date >= ?");
        args.add(startDate.toIso8601String());
      }
      if (endDate != null) {
        conditions.add("l.entry_date <= ?");
        args.add(endDate.toIso8601String());
      }

      final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';

      final sql = '''
        SELECT 
          l.*,
          p.name as project_name
        FROM labour_entries l
        JOIN projects p ON l.project_id = p.id
        $whereClause
        ORDER BY l.entry_date DESC, l.created_at DESC
      ''';

      final rows = await db.rawQuery(sql, args);
      final list = rows.map(LabourModel.fromMap).toList();
      return Result.success(list);
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to fetch labour shifts: $e'));
    }
  }
}
