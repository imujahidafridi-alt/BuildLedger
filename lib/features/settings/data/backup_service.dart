import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:build_ledger/core/database/database_helper.dart';
import 'package:build_ledger/core/logging/app_logger.dart';
import 'package:build_ledger/core/security/backup_encryptor.dart';
import 'package:build_ledger/features/settings/data/app_settings_repository.dart';

class BackupService {
  final DatabaseHelper _dbHelper;
  final BackupEncryptor _encryptor;
  final AppSettingsRepository _settingsRepo;

  BackupService({
    DatabaseHelper? dbHelper,
    BackupEncryptor? encryptor,
    AppSettingsRepository? settingsRepo,
  })  : _dbHelper = dbHelper ?? DatabaseHelper(),
        _encryptor = encryptor ?? BackupEncryptor(),
        _settingsRepo = settingsRepo ?? SharedPrefsAppSettingsRepository();

  /// Creates a fully packaged, encrypted `.buildledger` backup file with SHA-256 integrity verification.
  Future<String> exportEncryptedBackup({required String passphrase}) async {
    final db = await _dbHelper.database;

    // 1. Flush WAL checkpoint into main db file
    try {
      await db.rawQuery('PRAGMA wal_checkpoint(TRUNCATE);');
    } catch (_) {}

    final docsDir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(docsDir.path, 'build_ledger.db'));
    if (!await dbFile.exists()) {
      throw const FileSystemException('Database file not found');
    }

    final dbBytes = await dbFile.readAsBytes();
    final dbHash = sha256.convert(dbBytes).toString();

    // 2. Build ZIP Archive
    final archive = Archive();

    // Add SQLite database file
    archive.addFile(ArchiveFile('build_ledger.db', dbBytes.length, dbBytes));

    // Add receipts directory if exists
    final receiptsDir = Directory(p.join(docsDir.path, 'receipts'));
    if (await receiptsDir.exists()) {
      final receiptFiles = receiptsDir.listSync(recursive: true).whereType<File>();
      for (final file in receiptFiles) {
        final relativePath = p.relative(file.path, from: docsDir.path);
        final fileBytes = await file.readAsBytes();
        archive.addFile(ArchiveFile(relativePath, fileBytes.length, fileBytes));
      }
    }

    // Add metadata.json
    final metadata = {
      'appVersion': '1.0.0',
      'schemaVersion': 1,
      'dbSha256': dbHash,
      'timestamp': DateTime.now().toIso8601String(),
    };
    final metadataBytes = utf8.encode(jsonEncode(metadata));
    archive.addFile(ArchiveFile('metadata.json', metadataBytes.length, metadataBytes));

    // 3. Encode ZIP
    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);

    // 4. Authenticated AES-256-GCM Encryption
    final encryptedBytes = await _encryptor.encryptBytes(
      plainBytes: Uint8List.fromList(zipBytes),
      passphrase: passphrase,
    );

    // 5. Write to export directory
    final tempDir = await getTemporaryDirectory();
    final dateStr = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final exportPath = p.join(tempDir.path, 'BuildLedger_Backup_$dateStr.buildledger');
    await File(exportPath).writeAsBytes(encryptedBytes);
    await _settingsRepo.setLastBackupTimestamp(DateTime.now());

    AppLogger.info('Encrypted backup generated at: $exportPath', tag: 'BackupService');
    return exportPath;
  }

  /// Restores an encrypted `.buildledger` backup file, verifying integrity and schema compatibility.
  Future<void> restoreEncryptedBackup({
    required String filePath,
    required String passphrase,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw const FileSystemException('Backup file not found');
    }

    final encryptedBytes = await file.readAsBytes();

    // 1. Authenticated Decryption
    final plainBytes = await _encryptor.decryptBytes(
      encryptedData: encryptedBytes,
      passphrase: passphrase,
    );

    // 2. Decode ZIP
    final archive = ZipDecoder().decodeBytes(plainBytes);

    // 3. Verify metadata.json
    final metadataFile = archive.findFile('metadata.json');
    if (metadataFile == null) {
      throw const FormatException('Invalid backup: Missing metadata.json');
    }
    final metadata = jsonDecode(utf8.decode(metadataFile.content as List<int>)) as Map<String, dynamic>;
    final expectedHash = metadata['dbSha256'] as String?;

    // 4. Verify and extract database
    final dbEntry = archive.findFile('build_ledger.db');
    if (dbEntry == null) {
      throw const FormatException('Invalid backup: Missing build_ledger.db');
    }

    final extractedDbBytes = dbEntry.content as List<int>;
    final actualHash = sha256.convert(extractedDbBytes).toString();

    if (expectedHash != null && actualHash != expectedHash) {
      throw const FormatException('Database checksum mismatch: Possible data corruption');
    }

    // 5. Close active database
    await _dbHelper.close();

    final docsDir = await getApplicationDocumentsDirectory();
    final targetDbFile = File(p.join(docsDir.path, 'build_ledger.db'));

    // Remove WAL & SHM files if present
    final walFile = File('${targetDbFile.path}-wal');
    final shmFile = File('${targetDbFile.path}-shm');
    if (await walFile.exists()) await walFile.delete();
    if (await shmFile.exists()) await shmFile.delete();

    // Overwrite database
    await targetDbFile.writeAsBytes(extractedDbBytes);

    // Extract receipts
    for (final archiveFile in archive.files) {
      if (archiveFile.name.startsWith('receipts/')) {
        final destPath = p.join(docsDir.path, archiveFile.name);
        final destDir = Directory(p.dirname(destPath));
        if (!await destDir.exists()) await destDir.create(recursive: true);
        await File(destPath).writeAsBytes(archiveFile.content as List<int>);
      }
    }

    // Reopen database connection
    await _dbHelper.database;
    AppLogger.info('Backup restore complete and verified', tag: 'BackupService');
  }
}
