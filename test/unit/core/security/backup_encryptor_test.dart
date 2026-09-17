import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:build_ledger/core/security/backup_encryptor.dart';

void main() {
  late BackupEncryptor encryptor;

  setUp(() {
    encryptor = BackupEncryptor();
  });

  group('Authenticated Backup Encryption (AES-256-GCM)', () {
    test('successfully encrypts and decrypts with correct passphrase', () async {
      final sampleData = Uint8List.fromList('BuildLedger Database SQLite Content Payload 123456'.codeUnits);
      const passphrase = 'SuperSecretConstructionKey2026!';

      final encrypted = await encryptor.encryptBytes(
        plainBytes: sampleData,
        passphrase: passphrase,
      );

      expect(encrypted.length, greaterThan(sampleData.length));

      final decrypted = await encryptor.decryptBytes(
        encryptedData: encrypted,
        passphrase: passphrase,
      );

      expect(decrypted, equals(sampleData));
    });

    test('fails immediately when wrong passphrase is provided', () async {
      final sampleData = Uint8List.fromList('Sensitive Financial Ledger Data'.codeUnits);
      const correctPass = 'Key123';
      const wrongPass = 'Key999';

      final encrypted = await encryptor.encryptBytes(
        plainBytes: sampleData,
        passphrase: correctPass,
      );

      expect(
        () async => await encryptor.decryptBytes(
          encryptedData: encrypted,
          passphrase: wrongPass,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('fails authenticated decryption if payload is tampered', () async {
      final sampleData = Uint8List.fromList('Sensitive Financial Ledger Data'.codeUnits);
      const pass = 'Key123';

      final encrypted = await encryptor.encryptBytes(
        plainBytes: sampleData,
        passphrase: pass,
      );

      // Flip a single bit in the ciphertext to simulate tampering or corruption
      encrypted[encrypted.length - 1] ^= 0xFF;

      expect(
        () async => await encryptor.decryptBytes(
          encryptedData: encrypted,
          passphrase: pass,
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
