import 'package:sqflite/sqflite.dart';
import 'package:build_ledger/core/database/database_helper.dart';
import 'package:build_ledger/core/logging/app_logger.dart';

/// Provides application-level transaction boundaries ensuring atomic multi-table execution.
class TransactionRunner {
  final DatabaseHelper _databaseHelper;

  TransactionRunner([DatabaseHelper? databaseHelper])
      : _databaseHelper = databaseHelper ?? DatabaseHelper();

  /// Runs an atomic database transaction.
  /// If any operation within [action] throws an exception, the entire transaction is rolled back.
  Future<T> run<T>(Future<T> Function(Transaction txn) action) async {
    final db = await _databaseHelper.database;
    try {
      return await db.transaction<T>((txn) async {
        return await action(txn);
      });
    } catch (e, st) {
      AppLogger.error('Transaction failed and rolled back', tag: 'TransactionRunner', error: e, stackTrace: st);
      rethrow;
    }
  }
}
