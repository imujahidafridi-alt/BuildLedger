import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:build_ledger/app/app.dart';
import 'package:build_ledger/core/database/database_helper.dart';
import 'package:build_ledger/core/logging/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite database and migrations
  try {
    final dbHelper = DatabaseHelper();
    await dbHelper.database;
    AppLogger.info('BuildLedger Database Engine initialized', tag: 'Main');
  } catch (e, st) {
    AppLogger.error('Failed to initialize database engine', tag: 'Main', error: e, stackTrace: st);
  }

  runApp(
    const ProviderScope(
      child: BuildLedgerApp(),
    ),
  );
}
