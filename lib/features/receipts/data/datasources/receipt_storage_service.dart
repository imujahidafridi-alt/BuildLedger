import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:build_ledger/core/logging/app_logger.dart';

/// Two-Phase receipt media manager decoupling disk I/O and compression from SQLite transactions.
class ReceiptStorageService {
  final ImagePicker _picker;

  ReceiptStorageService([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  /// Phase 1: Capture or pick photo and save to temporary staging cache.
  Future<String?> stageReceipt({required ImageSource source}) async {
    try {
      final xFile = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80, // High quality, low storage footprint (<250KB)
      );

      if (xFile == null) return null;

      final tempDir = await getTemporaryDirectory();
      final stagingFolder = Directory(p.join(tempDir.path, 'staging_receipts'));
      if (!await stagingFolder.exists()) {
        await stagingFolder.create(recursive: true);
      }

      final stagingPath = p.join(stagingFolder.path, '${const Uuid().v4()}.jpg');
      await File(xFile.path).copy(stagingPath);
      AppLogger.info('Staged receipt image at: $stagingPath', tag: 'ReceiptStorageService');
      return stagingPath;
    } catch (e) {
      AppLogger.error('Failed to stage receipt image', tag: 'ReceiptStorageService', error: e);
      return null;
    }
  }

  /// Phase 2: Promote staged receipt to permanent sandboxed storage upon database commit success.
  Future<String> promoteReceipt({
    required String stagedPath,
    required String projectId,
    required String expenseId,
  }) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final permanentFolder = Directory(p.join(docsDir.path, 'receipts', projectId));
    if (!await permanentFolder.exists()) {
      await permanentFolder.create(recursive: true);
    }

    final permanentPath = p.join(permanentFolder.path, '$expenseId.jpg');
    final stagedFile = File(stagedPath);
    if (await stagedFile.exists()) {
      await stagedFile.rename(permanentPath);
      AppLogger.info('Promoted receipt to: $permanentPath', tag: 'ReceiptStorageService');
    }
    return permanentPath;
  }

  /// Phase 2 Rollback: Discard staged file if database transaction fails.
  Future<void> discardStagedReceipt(String? stagedPath) async {
    if (stagedPath == null) return;
    try {
      final file = File(stagedPath);
      if (await file.exists()) {
        await file.delete();
        AppLogger.info('Cleaned up orphan staged receipt: $stagedPath', tag: 'ReceiptStorageService');
      }
    } catch (_) {}
  }
}
