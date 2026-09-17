import 'package:uuid/uuid.dart';
import 'package:build_ledger/core/database/database_helper.dart';
import 'package:build_ledger/core/database/transaction_runner.dart';
import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/core/domain/result.dart';
import 'package:build_ledger/core/errors/app_failure.dart';
import 'package:build_ledger/features/suppliers/domain/entities/supplier.dart';
import 'package:build_ledger/features/suppliers/domain/entities/supplier_ledger_entry.dart';
import 'package:build_ledger/features/suppliers/domain/repositories/supplier_repository.dart';
import 'package:build_ledger/features/suppliers/data/models/supplier_model.dart';
import 'package:build_ledger/features/suppliers/data/models/supplier_ledger_model.dart';

class SupplierRepositoryImpl implements SupplierRepository {
  final DatabaseHelper _dbHelper;
  final TransactionRunner _transactionRunner;

  SupplierRepositoryImpl({
    DatabaseHelper? dbHelper,
    TransactionRunner? transactionRunner,
  })  : _dbHelper = dbHelper ?? DatabaseHelper(),
        _transactionRunner = transactionRunner ?? TransactionRunner();

  @override
  Future<Result<Supplier>> createSupplier(Supplier supplier, {Money? openingBalance}) async {
    try {
      final now = DateTime.now();
      await _transactionRunner.run((txn) async {
        // 1. Insert supplier
        await txn.insert('suppliers', SupplierModel.toMap(supplier));

        // 2. Authoritative Opening Balance as initial ledger entry if provided
        if (openingBalance != null && openingBalance.isPositive) {
          final openingEntry = SupplierLedgerEntry(
            id: const Uuid().v4(),
            supplierId: supplier.id,
            projectId: null,
            direction: LedgerDirection.credit,
            entryType: LedgerEntryType.openingBalance,
            amount: openingBalance,
            description: 'Opening Balance',
            entryDate: now,
            createdAt: now,
          );
          await txn.insert('supplier_ledger', SupplierLedgerModel.toMap(openingEntry));
        }

        // 3. Audit trail
        await txn.insert('audit_logs', {
          'id': const Uuid().v4(),
          'entity_type': 'supplier',
          'entity_id': supplier.id,
          'action': 'create',
          'actor': 'local_user',
          'payload_before': null,
          'payload_after': supplier.name,
          'timestamp': now.toIso8601String(),
        });
      });

      return Result.success(supplier.copyWith(
        currentBalance: openingBalance ?? Money.zero,
      ));
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to create supplier: $e'));
    }
  }

  @override
  Future<Result<List<Supplier>>> getSuppliers({bool includeArchived = false}) async {
    try {
      final db = await _dbHelper.database;
      final whereClause = includeArchived ? '' : 'WHERE s.archived_at IS NULL';

      // Authoritative ledger sum: Credits (Purchases/Opening) minus Debits (Payments/Refunds)
      final sql = '''
        SELECT 
          s.*,
          COALESCE(SUM(CASE WHEN l.direction = 'credit' THEN l.amount_minor ELSE -l.amount_minor END), 0) as balance_minor
        FROM suppliers s
        LEFT JOIN supplier_ledger l ON s.id = l.supplier_id
        $whereClause
        GROUP BY s.id
        ORDER BY s.name ASC
      ''';

      final rows = await db.rawQuery(sql);
      final list = rows.map((row) {
        final balance = Money.fromMinor(row['balance_minor'] as int);
        return SupplierModel.fromMap(row, balance);
      }).toList();

      return Result.success(list);
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to fetch suppliers: $e'));
    }
  }

  @override
  Future<Result<Supplier?>> getSupplierById(String id) async {
    try {
      final db = await _dbHelper.database;
      final sql = '''
        SELECT 
          s.*,
          COALESCE(SUM(CASE WHEN l.direction = 'credit' THEN l.amount_minor ELSE -l.amount_minor END), 0) as balance_minor
        FROM suppliers s
        LEFT JOIN supplier_ledger l ON s.id = l.supplier_id
        WHERE s.id = ?
        GROUP BY s.id
        LIMIT 1
      ''';

      final rows = await db.rawQuery(sql, [id]);
      if (rows.isEmpty) return const Result.success(null);

      final balance = Money.fromMinor(rows.first['balance_minor'] as int);
      return Result.success(SupplierModel.fromMap(rows.first, balance));
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to fetch supplier: $e'));
    }
  }

  @override
  Future<Result<List<SupplierLedgerEntry>>> getSupplierLedger(String supplierId) async {
    try {
      final db = await _dbHelper.database;
      final rows = await db.query(
        'supplier_ledger',
        where: 'supplier_id = ?',
        whereArgs: [supplierId],
        orderBy: 'entry_date DESC, created_at DESC',
      );

      final entries = rows.map(SupplierLedgerModel.fromMap).toList();
      return Result.success(entries);
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to fetch supplier ledger: $e'));
    }
  }

  @override
  Future<Result<SupplierLedgerEntry>> recordPayment({
    required String supplierId,
    String? projectId,
    required Money amount,
    required String description,
    required DateTime date,
    String? referenceId,
  }) async {
    try {
      final now = DateTime.now();
      final entry = SupplierLedgerEntry(
        id: const Uuid().v4(),
        supplierId: supplierId,
        projectId: projectId,
        direction: LedgerDirection.debit, // Payments reduce liability
        entryType: LedgerEntryType.payment,
        amount: amount,
        referenceId: referenceId,
        description: description,
        entryDate: date,
        createdAt: now,
      );

      await _transactionRunner.run((txn) async {
        await txn.insert('supplier_ledger', SupplierLedgerModel.toMap(entry));
        await txn.insert('audit_logs', {
          'id': const Uuid().v4(),
          'entity_type': 'supplier_ledger',
          'entity_id': entry.id,
          'action': 'create',
          'actor': 'local_user',
          'payload_before': null,
          'payload_after': 'Payment of ${amount.minorUnits} to $supplierId',
          'timestamp': now.toIso8601String(),
        });
      });

      return Result.success(entry);
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to record supplier payment: $e'));
    }
  }

  @override
  Future<Result<void>> archiveSupplier(String id) async {
    try {
      final now = DateTime.now().toIso8601String();
      final db = await _dbHelper.database;
      await db.update(
        'suppliers',
        {'archived_at': now, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [id],
      );
      return const Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseFailure('Failed to archive supplier: $e'));
    }
  }
}
