import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

/// AES-256-GCM encryption service for securing sensitive local data.
///
/// Uses Authenticated Encryption (GCM) for both confidentiality and integrity.
/// The encryption key is generated once and stored in the platform's
/// secure keystore (Android Keystore / iOS Keychain).
///
/// Encrypted values are stored as: `base64(iv):base64(ciphertext+tag)`
/// Supports backward compatibility for legacy AES-CBC data.
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._();
  static EncryptionService get instance => _instance;

  EncryptionService._();

  static const String _keyStorageKey = 'wallet_aes_256_master_key';
  static const String _migrationFlagKey = 'wallet_encryption_migrated';

  // AES-GCM standard nonce (IV) length is 12 bytes (96 bits)
  static const int _gcmIvLength = 12;
  // Legacy AES-CBC IV length is 16 bytes
  static const int _cbcIvLength = 16;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  encrypt.Key? _encryptionKey;
  bool _isInitialized = false;

  /// Whether the service has been initialized and is ready to use.
  bool get isInitialized => _isInitialized;

  /// Initialize the encryption service.
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      String? storedKey = await _secureStorage.read(key: _keyStorageKey);

      if (storedKey == null) {
        // First launch — generate a new 256-bit key
        final keyBytes = _generateSecureRandomBytes(32); // 256 bits
        storedKey = base64Encode(keyBytes);
        await _secureStorage.write(key: _keyStorageKey, value: storedKey);
        debugPrint('EncryptionService: New AES-256 key generated and stored.');
      }

      _encryptionKey = encrypt.Key.fromBase64(storedKey);
      _isInitialized = true;
      debugPrint('EncryptionService: Initialized successfully.');
    } catch (e) {
      _isInitialized = false;
      debugPrint('EncryptionService: Initialization failed: $e');
      rethrow;
    }
  }

  /// Generate cryptographically secure random bytes.
  Uint8List _generateSecureRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }

  /// Encrypt a plaintext string using AES-256-GCM with a random 12-byte IV.
  ///
  /// Returns a string in the format: `base64(iv):base64(ciphertext)`
  /// where ciphertext includes the 16-byte authentication tag at the end.
  String? encryptText(String? plaintext) {
    if (plaintext == null || plaintext.isEmpty) return plaintext;
    if (!_isInitialized || _encryptionKey == null) {
      throw StateError(
        'EncryptionService: Not initialized. Call init() first.',
      );
    }

    try {
      final iv = encrypt.IV(_generateSecureRandomBytes(_gcmIvLength));
      final encrypter = encrypt.Encrypter(
        encrypt.AES(_encryptionKey!, mode: encrypt.AESMode.gcm),
      );
      final encrypted = encrypter.encrypt(plaintext, iv: iv);

      // Format: iv:ciphertext (both base64)
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      debugPrint('EncryptionService: Encryption failed: $e');
      throw Exception('Failed to encrypt sensitive data: $e');
    }
  }

  /// Decrypt an encrypted string (format: `base64(iv):base64(ciphertext)`).
  ///
  /// Automatically detects if the data is legacy CBC or new GCM based on IV length.
  String? decryptText(String? ciphertext) {
    if (ciphertext == null || ciphertext.isEmpty) return ciphertext;
    if (!_isInitialized || _encryptionKey == null) {
      throw StateError(
        'EncryptionService: Not initialized. Call init() first.',
      );
    }

    if (!_isEncrypted(ciphertext)) {
      return ciphertext;
    }

    try {
      final parts = ciphertext.split(':');
      final iv = encrypt.IV.fromBase64(parts[0]);
      final encryptedData = encrypt.Encrypted.fromBase64(parts[1]);

      // Detect mode based on IV length: 12 bytes = GCM, 16 bytes = CBC
      final mode = iv.bytes.length == _gcmIvLength
          ? encrypt.AESMode.gcm
          : encrypt.AESMode.cbc;

      final encrypter = encrypt.Encrypter(
        encrypt.AES(_encryptionKey!, mode: mode),
      );
      return encrypter.decrypt(encryptedData, iv: iv);
    } catch (e) {
      debugPrint('EncryptionService: Decryption failed: $e');
      throw Exception('Failed to decrypt sensitive data: $e');
    }
  }

  /// Check if a string looks like it was encrypted by this service.
  bool _isEncrypted(String value) {
    if (!value.contains(':')) return false;

    final parts = value.split(':');
    if (parts.length != 2) return false;

    try {
      final ivBytes = base64Decode(parts[0]);
      // Accept both 12-byte (GCM) and 16-byte (CBC) IVs
      if (ivBytes.length != _gcmIvLength && ivBytes.length != _cbcIvLength) {
        return false;
      }

      base64Decode(parts[1]);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Encrypt a JSON-serializable map using AES-256-GCM.
  String? encryptJson(Map<String, dynamic>? data) {
    if (data == null) return null;
    return encryptText(jsonEncode(data));
  }

  /// Decrypt a JSON string that was encrypted (supports GCM and CBC).
  Map<String, String>? decryptJsonToStringMap(String? encrypted) {
    if (encrypted == null) return null;

    final decrypted = decryptText(encrypted);
    if (decrypted == null) return null;

    try {
      return Map<String, String>.from(jsonDecode(decrypted));
    } catch (e) {
      debugPrint('EncryptionService: JSON parse failed: $e');
      return null;
    }
  }

  /// Encrypt data for backup using AES-256-GCM with a password-derived key.
  ///
  /// Output format: `base64(salt):base64(iv):base64(ciphertext)`
  Uint8List encryptForBackup(String data, String password) {
    final salt = _generateSecureRandomBytes(16);
    final keyBytes = _deriveKeyPBKDF2(password, salt);
    final key = encrypt.Key(Uint8List.fromList(keyBytes));
    final iv = encrypt.IV(_generateSecureRandomBytes(_gcmIvLength));

    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.gcm),
    );
    final encrypted = encrypter.encrypt(data, iv: iv);

    final saltB64 = base64Encode(salt);
    final ivB64 = iv.base64;
    final cipherB64 = encrypted.base64;
    return utf8.encode('$saltB64:$ivB64:$cipherB64');
  }

  /// Decrypt backup data (supports AES-256-GCM and legacy AES-256-CBC).
  String decryptForBackup(Uint8List encryptedData, String password) {
    try {
      final content = utf8.decode(encryptedData);
      final parts = content.split(':');

      if (parts.length == 3) {
        // Format with salt: base64(salt):base64(iv):base64(ciphertext)
        final salt = base64Decode(parts[0]);
        final iv = encrypt.IV.fromBase64(parts[1]);
        final ciphertext = encrypt.Encrypted.fromBase64(parts[2]);

        final keyBytes = _deriveKeyPBKDF2(password, salt);
        final key = encrypt.Key(Uint8List.fromList(keyBytes));

        final mode = iv.bytes.length == _gcmIvLength
            ? encrypt.AESMode.gcm
            : encrypt.AESMode.cbc;

        final encrypter = encrypt.Encrypter(
          encrypt.AES(key, mode: mode),
        );
        return encrypter.decrypt(ciphertext, iv: iv);
      } else if (parts.length == 2) {
        // Legacy format without salt: base64(iv):base64(ciphertext)
        final iv = encrypt.IV.fromBase64(parts[0]);
        final ciphertext = encrypt.Encrypted.fromBase64(parts[1]);

        final keyBytes = _deriveKeyFromPassword(password);
        final key = encrypt.Key(Uint8List.fromList(keyBytes));

        // Legacy format without salt was always CBC
        final encrypter = encrypt.Encrypter(
          encrypt.AES(key, mode: encrypt.AESMode.cbc),
        );
        return encrypter.decrypt(ciphertext, iv: iv);
      }
    } catch (e) {
      // Not UTF-8 or failed to decrypt
    }

    return _decryptLegacyBackup(encryptedData, password);
  }

  /// Decrypt legacy raw byte backup (always CBC).
  String _decryptLegacyBackup(Uint8List encryptedData, String password) {
    if (encryptedData.length < 17) {
      throw Exception('Invalid encrypted data: too short');
    }

    final keyBytes = _deriveKeyFromPassword(password);
    final key = encrypt.Key(Uint8List.fromList(keyBytes));

    final iv = encrypt.IV(Uint8List.fromList(encryptedData.sublist(0, 16)));
    final ciphertext = encrypt.Encrypted(
      Uint8List.fromList(encryptedData.sublist(16)),
    );

    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc),
    );
    return encrypter.decrypt(ciphertext, iv: iv);
  }

  /// Derive a 256-bit key using PBKDF2-HMAC-SHA256 with 100,000 iterations.
  List<int> _deriveKeyPBKDF2(String password, List<int> salt) {
    final passwordBytes = utf8.encode(password);
    var block1 = Uint8List.fromList(
      Hmac(sha256, passwordBytes).convert(salt).bytes,
    );

    var u = block1;
    for (int i = 1; i < 100000; i++) {
      u = Uint8List.fromList(Hmac(sha256, passwordBytes).convert(u).bytes);
      for (int j = 0; j < block1.length; j++) {
        block1[j] ^= u[j];
      }
    }

    return block1;
  }

  /// Derive a 256-bit key from a password using multiple rounds of SHA-256.
  List<int> _deriveKeyFromPassword(String password) {
    const salt = 'wallet_app_aes256_salt_v1';
    var bytes = utf8.encode('$password:$salt');

    for (int i = 0; i < 10000; i++) {
      bytes = Uint8List.fromList(sha256.convert(bytes).bytes);
    }

    return bytes;
  }

  /// Encrypt an image file using AES-256-GCM.
  Future<String?> encryptImageFile(String sourceFilePath) async {
    try {
      if (!_isInitialized || _encryptionKey == null) {
        throw StateError('EncryptionService: Not initialized.');
      }

      final sourceFile = File(sourceFilePath);
      if (!await sourceFile.exists()) {
        debugPrint('EncryptionService: Source image file not found.');
        return null;
      }

      final imageBytes = await sourceFile.readAsBytes();
      final iv = encrypt.IV(_generateSecureRandomBytes(_gcmIvLength));
      final encrypter = encrypt.Encrypter(
        encrypt.AES(_encryptionKey!, mode: encrypt.AESMode.gcm),
      );
      final encrypted = encrypter.encryptBytes(imageBytes, iv: iv);

      // Store as: base64(iv):base64(ciphertext)
      final encryptedContent = '${iv.base64}:${encrypted.base64}';

      final encryptedPath = '$sourceFilePath.enc';
      final encryptedFile = File(encryptedPath);
      await encryptedFile.writeAsString(encryptedContent);

      await sourceFile.delete();

      debugPrint(
        'EncryptionService: Image encrypted successfully: $encryptedPath',
      );
      return encryptedPath;
    } catch (e) {
      debugPrint('EncryptionService: Image encryption failed: $e');
      throw Exception('Failed to encrypt image: $e');
    }
  }

  /// Decrypt an encrypted image file and return the raw bytes.
  ///
  /// This is the preferred method as it avoids writing sensitive data
  /// to disk in plaintext. The returned bytes can be used with `Image.memory`.
  Future<Uint8List?> decryptImageToBytes(String encryptedFilePath) async {
    try {
      if (!_isInitialized || _encryptionKey == null) {
        throw StateError('EncryptionService: Not initialized.');
      }

      final encryptedFile = File(encryptedFilePath);
      if (!await encryptedFile.exists()) {
        debugPrint('EncryptionService: Encrypted image file not found.');
        return null;
      }

      final content = await encryptedFile.readAsString();
      if (!_isEncrypted(content)) {
        // File is not encrypted, read as raw bytes
        return await encryptedFile.readAsBytes();
      }

      final parts = content.split(':');
      final iv = encrypt.IV.fromBase64(parts[0]);
      final encryptedData = encrypt.Encrypted.fromBase64(parts[1]);

      final mode = iv.bytes.length == _gcmIvLength
          ? encrypt.AESMode.gcm
          : encrypt.AESMode.cbc;

      final encrypter = encrypt.Encrypter(
        encrypt.AES(_encryptionKey!, mode: mode),
      );
      final decryptedBytes = encrypter.decryptBytes(encryptedData, iv: iv);

      return Uint8List.fromList(decryptedBytes);
    } catch (e) {
      debugPrint('EncryptionService: Image decryption failed: $e');
      throw Exception('Failed to decrypt image: $e');
    }
  }

  /// Check whether existing data has been migrated to encrypted format.
  Future<bool> isMigrated() async {
    final flag = await _secureStorage.read(key: _migrationFlagKey);
    return flag == 'true';
  }

  /// Mark the database as having been migrated to encrypted format.
  Future<void> markMigrated() async {
    await _secureStorage.write(key: _migrationFlagKey, value: 'true');
  }
}
