import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:build_ledger/core/database/database_helper.dart';
import 'package:build_ledger/core/logging/app_logger.dart';
import 'package:build_ledger/features/settings/domain/entities/database_diagnostics.dart';

class DatabaseDiagnosticsService {
  final DatabaseHelper _dbHelper;

  DatabaseDiagnosticsService({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<DatabaseDiagnostics> getDiagnostics() async {
    final db = await _dbHelper.database;

    // 1. Calculate file size safely
    int fileSizeBytes = 0;
    try {
      if (!kIsWeb && db.path.isNotEmpty && db.path != ':memory:') {
        final file = File(db.path);
        if (await file.exists()) {
          fileSizeBytes = await file.length();
        }
      }
    } catch (_) {}

    // Fallback if file size couldn't be read directly (e.g. in-memory or web)
    if (fileSizeBytes <= 0) {
      try {
        final pageCountRes = await db.rawQuery('PRAGMA page_count;');
        final pageSizeRes = await db.rawQuery('PRAGMA page_size;');
        final pageCount = Sqflite.firstIntValue(pageCountRes) ?? 0;
        final pageSize = Sqflite.firstIntValue(pageSizeRes) ?? 4096;
        fileSizeBytes = pageCount * pageSize;
      } catch (_) {}
    }

    // 2. Query SQLite engine version
    String sqliteVersion = '3.x';
    try {
      final res = await db.rawQuery('SELECT sqlite_version() AS version;');
      if (res.isNotEmpty && res.first['version'] != null) {
        sqliteVersion = res.first['version'] as String;
      }
    } catch (_) {}

    // 3. Query journal mode (e.g. wal, delete)
    String journalMode = 'wal';
    try {
      final res = await db.rawQuery('PRAGMA journal_mode;');
      if (res.isNotEmpty && res.first.values.isNotEmpty) {
        journalMode = res.first.values.first.toString();
      }
    } catch (_) {}

    // 4. Query record counts from major operational tables
    int projectCount = 0;
    int expenseCount = 0;
    int supplierCount = 0;
    int labourCount = 0;
    int categoryCount = 0;

    try {
      projectCount = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM projects;')) ??
          0;
    } catch (_) {}

    try {
      expenseCount = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM expenses;')) ??
          0;
    } catch (_) {}

    try {
      supplierCount = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM suppliers;')) ??
          0;
    } catch (_) {}

    try {
      labourCount = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM labour_entries;')) ??
          0;
    } catch (_) {}

    try {
      categoryCount = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM expense_categories;')) ??
          0;
    } catch (_) {}

    return DatabaseDiagnostics(
      fileSizeBytes: fileSizeBytes,
      sqliteVersion: sqliteVersion,
      journalMode: journalMode.toUpperCase(),
      databasePath: db.path,
      projectCount: projectCount,
      expenseCount: expenseCount,
      supplierCount: supplierCount,
      labourCount: labourCount,
      categoryCount: categoryCount,
    );
  }

  /// Reclaims freed storage, defragments pages, and optimizes B-tree indexes.
  Future<void> optimizeDatabase() async {
    final db = await _dbHelper.database;
    AppLogger.info('Starting SQLite VACUUM optimization', tag: 'DatabaseDiagnostics');
    try {
      await db.execute('VACUUM;');
      AppLogger.info('SQLite VACUUM optimization completed', tag: 'DatabaseDiagnostics');
    } catch (e, st) {
      AppLogger.error('SQLite VACUUM failed', error: e, stackTrace: st, tag: 'DatabaseDiagnostics');
      rethrow;
    }
  }
}
