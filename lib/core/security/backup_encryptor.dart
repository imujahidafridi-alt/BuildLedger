import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:build_ledger/core/logging/app_logger.dart';

/// Authenticated encryption engine using AES-256-GCM and PBKDF2 key derivation.
class BackupEncryptor {
  static const List<int> magicHeader = [0x42, 0x4C, 0x42, 0x4B, 0x30, 0x31]; // 'BLBK01'
  static const int saltLength = 16;
  static const int nonceLength = 12;
  static const int macLength = 16;
  static const int pbkdf2Iterations = 100000;

  final AesGcm _aesGcm = AesGcm.with256bits();
  final Pbkdf2 _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: pbkdf2Iterations,
    bits: 256,
  );

  /// Encrypts raw bytes (e.g. ZIP archive) with authenticated AES-256-GCM using [passphrase].
  Future<Uint8List> encryptBytes({
    required Uint8List plainBytes,
    required String passphrase,
  }) async {
    AppLogger.info('Encrypting backup package (${plainBytes.length} bytes)', tag: 'BackupEncryptor');

    // 1. Generate 16-byte random salt
    final secretKey = SecretKey(passphrase.codeUnits);
    final saltRaw = _aesGcm.newNonce();
    final salt = saltRaw.length >= saltLength
        ? saltRaw.sublist(0, saltLength)
        : Uint8List.fromList([...saltRaw, ...List.filled(saltLength - saltRaw.length, 0)]);

    // 2. Derive 256-bit Key via PBKDF2
    final derivedKey = await _pbkdf2.deriveKey(
      secretKey: secretKey,
      nonce: salt,
    );

    // 3. Generate 12-byte random Nonce/IV
    final nonceRaw = _aesGcm.newNonce();
    final nonce = nonceRaw.length >= nonceLength
        ? nonceRaw.sublist(0, nonceLength)
        : Uint8List.fromList([...nonceRaw, ...List.filled(nonceLength - nonceRaw.length, 0)]);

    // 4. Authenticated Encryption via AES-256-GCM
    final secretBox = await _aesGcm.encrypt(
      plainBytes,
      secretKey: derivedKey,
      nonce: nonce,
    );

    // Format: [MAGIC (6)] + [SALT (16)] + [NONCE (12)] + [MAC (16)] + [CIPHERTEXT]
    final output = BytesBuilder();
    output.add(magicHeader);
    output.add(salt);
    output.add(nonce);
    output.add(secretBox.mac.bytes);
    output.add(secretBox.cipherText);

    final result = output.toBytes();
    AppLogger.info('Backup successfully encrypted (${result.length} bytes)', tag: 'BackupEncryptor');
    return result;
  }

  /// Decrypts authenticated AES-256-GCM backup package.
  /// Throws [FormatException] if passphrase is wrong, header is invalid, or payload is tampered.
  Future<Uint8List> decryptBytes({
    required Uint8List encryptedData,
    required String passphrase,
  }) async {
    const headerLen = 6;
    const minLength = headerLen + saltLength + nonceLength + macLength + 1;
    if (encryptedData.length < minLength) {
      throw const FormatException('Invalid backup file: Payload too small');
    }

    // 1. Verify Magic Header
    for (int i = 0; i < headerLen; i++) {
      if (encryptedData[i] != magicHeader[i]) {
        throw const FormatException('Invalid backup file format: Magic header mismatch');
      }
    }

    int offset = headerLen;
    final salt = encryptedData.sublist(offset, offset + saltLength);
    offset += saltLength;

    final nonce = encryptedData.sublist(offset, offset + nonceLength);
    offset += nonceLength;

    final macBytes = encryptedData.sublist(offset, offset + macLength);
    offset += macLength;

    final cipherText = encryptedData.sublist(offset);

    // 2. Derive Key
    final secretKey = SecretKey(passphrase.codeUnits);
    final derivedKey = await _pbkdf2.deriveKey(
      secretKey: secretKey,
      nonce: salt,
    );

    // 3. Authenticated Decryption with GCM Tag Verification
    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    try {
      final decrypted = await _aesGcm.decrypt(
        secretBox,
        secretKey: derivedKey,
      );
      return Uint8List.fromList(decrypted);
    } catch (e) {
      throw FormatException('Decryption failed: Incorrect password or corrupted backup ($e)');
    }
  }
}
