import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

/// AES-256-CBC encryption service for securing sensitive local data.
///
/// The encryption key is generated once and stored in the platform's
/// secure keystore (Android Keystore / iOS Keychain), making it
/// inaccessible even on rooted devices without significant effort.
///
/// Encrypted values are stored as: `base64(iv):base64(ciphertext)`
/// so each field gets a unique random IV.
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._();
  static EncryptionService get instance => _instance;

  EncryptionService._();

  static const String _keyStorageKey = 'wallet_aes_256_master_key';
  static const String _migrationFlagKey = 'wallet_encryption_migrated';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  encrypt.Key? _encryptionKey;
  bool _isInitialized = false;

  /// Whether the service has been initialized and is ready to use.
  bool get isInitialized => _isInitialized;

  /// Initialize the encryption service.
  /// Must be called once during app startup, before any DB operations.
  /// Throws an exception if secure storage is unavailable — fails securely.
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
      // FAIL SECURELY — do not use a fallback key.
      // If secure storage is unavailable, the app cannot function safely.
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

  /// Encrypt a plaintext string using AES-256-CBC with a random IV.
  ///
  /// Returns a string in the format: `base64(iv):base64(ciphertext)`
  /// Returns null if input is null.
  /// Throws an exception if encryption fails — never returns plaintext.
  String? encryptText(String? plaintext) {
    if (plaintext == null || plaintext.isEmpty) return plaintext;
    if (!_isInitialized || _encryptionKey == null) {
      throw StateError(
        'EncryptionService: Not initialized. Call init() first.',
      );
    }

    try {
      final iv = encrypt.IV(_generateSecureRandomBytes(16));
      final encrypter = encrypt.Encrypter(
        encrypt.AES(_encryptionKey!, mode: encrypt.AESMode.cbc),
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
  /// If the input doesn't look like an encrypted value (no `:` separator),
  /// it's returned as-is — this supports transparent migration of
  /// existing plaintext data.
  /// Throws an exception if decryption of an encrypted value fails.
  String? decryptText(String? ciphertext) {
    if (ciphertext == null || ciphertext.isEmpty) return ciphertext;
    if (!_isInitialized || _encryptionKey == null) {
      throw StateError(
        'EncryptionService: Not initialized. Call init() first.',
      );
    }

    // Check if this looks like an encrypted value (has iv:ciphertext format)
    if (!_isEncrypted(ciphertext)) {
      // This is plaintext from before encryption was added — return as-is
      return ciphertext;
    }

    try {
      final parts = ciphertext.split(':');
      final iv = encrypt.IV.fromBase64(parts[0]);
      final encryptedData = encrypt.Encrypted.fromBase64(parts[1]);

      final encrypter = encrypt.Encrypter(
        encrypt.AES(_encryptionKey!, mode: encrypt.AESMode.cbc),
      );
      return encrypter.decrypt(encryptedData, iv: iv);
    } catch (e) {
      debugPrint('EncryptionService: Decryption failed: $e');
      throw Exception('Failed to decrypt sensitive data: $e');
    }
  }

  /// Check if a string looks like it was encrypted by this service.
  /// Encrypted values have the format: base64(16 bytes):base64(n bytes)
  bool _isEncrypted(String value) {
    if (!value.contains(':')) return false;

    final parts = value.split(':');
    if (parts.length != 2) return false;

    try {
      // IV should be exactly 16 bytes when decoded from base64
      final ivBytes = base64Decode(parts[0]);
      if (ivBytes.length != 16) return false;

      // Ciphertext should be valid base64
      base64Decode(parts[1]);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Encrypt a JSON-serializable map (e.g. customFields).
  /// Returns encrypted JSON string or null.
  String? encryptJson(Map<String, dynamic>? data) {
    if (data == null) return null;
    return encryptText(jsonEncode(data));
  }

  /// Decrypt a JSON string that was encrypted.
  /// Handles both encrypted and plaintext JSON gracefully.
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

  /// Encrypt data for backup using AES-256-CBC with a password-derived key.
  ///
  /// Uses PBKDF2-HMAC-SHA256 with 100,000 iterations and a random salt
  /// (per OWASP 2023 recommendations).
  ///
  /// Output format: `base64(salt):base64(iv):base64(ciphertext)`
  Uint8List encryptForBackup(String data, String password) {
    // Generate a random 16-byte salt for this backup
    final salt = _generateSecureRandomBytes(16);

    // Derive key using PBKDF2-HMAC-SHA256 with 100,000 iterations
    final keyBytes = _deriveKeyPBKDF2(password, salt);
    final key = encrypt.Key(Uint8List.fromList(keyBytes));
    final iv = encrypt.IV(_generateSecureRandomBytes(16));

    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc),
    );
    final encrypted = encrypter.encrypt(data, iv: iv);

    // Format: base64(salt):base64(iv):base64(ciphertext)
    final saltB64 = base64Encode(salt);
    final ivB64 = iv.base64;
    final cipherB64 = encrypted.base64;
    return utf8.encode('$saltB64:$ivB64:$cipherB64');
  }

  /// Decrypt backup data using AES-256-CBC with a password-derived key.
  ///
  /// Supports two formats:
  /// - New format: UTF-8 encoded `base64(salt):base64(iv):base64(ciphertext)`
  /// - Legacy format: raw bytes with IV (first 16 bytes) + ciphertext
  String decryptForBackup(Uint8List encryptedData, String password) {
    // Try to detect the format by checking if it looks like valid UTF-8 text
    // with colons (our new text-based format)
    try {
      final content = utf8.decode(encryptedData);
      final parts = content.split(':');

      if (parts.length == 3) {
        // New format with salt
        final salt = base64Decode(parts[0]);
        final iv = encrypt.IV.fromBase64(parts[1]);
        final ciphertext = encrypt.Encrypted.fromBase64(parts[2]);

        final keyBytes = _deriveKeyPBKDF2(password, salt);
        final key = encrypt.Key(Uint8List.fromList(keyBytes));

        final encrypter = encrypt.Encrypter(
          encrypt.AES(key, mode: encrypt.AESMode.cbc),
        );
        return encrypter.decrypt(ciphertext, iv: iv);
      } else if (parts.length == 2) {
        // Old text-based format (if any): base64(iv):base64(ciphertext)
        final iv = encrypt.IV.fromBase64(parts[0]);
        final ciphertext = encrypt.Encrypted.fromBase64(parts[1]);

        final keyBytes = _deriveKeyFromPassword(password);
        final key = encrypt.Key(Uint8List.fromList(keyBytes));

        final encrypter = encrypt.Encrypter(
          encrypt.AES(key, mode: encrypt.AESMode.cbc),
        );
        return encrypter.decrypt(ciphertext, iv: iv);
      }
    } catch (e) {
      // If UTF-8 decoding fails, it's likely raw bytes (legacy format)
    }

    // Legacy format: raw bytes with IV (first 16 bytes) + ciphertext
    return _decryptLegacyBackup(encryptedData, password);
  }

  /// Decrypt legacy backup (old format without salt)
  /// Old format: raw bytes with IV (first 16 bytes) + ciphertext (remaining bytes)
  String _decryptLegacyBackup(Uint8List encryptedData, String password) {
    if (encryptedData.length < 17) {
      throw Exception('Invalid encrypted data: too short');
    }

    final keyBytes = _deriveKeyFromPassword(password);
    final key = encrypt.Key(Uint8List.fromList(keyBytes));

    // Extract IV (first 16 bytes)
    final iv = encrypt.IV(Uint8List.fromList(encryptedData.sublist(0, 16)));
    // Extract ciphertext (remaining bytes)
    final ciphertext = encrypt.Encrypted(
      Uint8List.fromList(encryptedData.sublist(16)),
    );

    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc),
    );
    return encrypter.decrypt(ciphertext, iv: iv);
  }

  /// Derive a 256-bit key using PBKDF2-HMAC-SHA256 with 100,000 iterations.
  /// Uses a random salt provided with each encrypted backup for maximum security.
  List<int> _deriveKeyPBKDF2(String password, List<int> salt) {
    // PBKDF2-HMAC-SHA256 implementation using the crypto package
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
  /// DEPRECATED: Use _deriveKeyPBKDF2 for new backups.
  /// This is kept for backward compatibility with very old backups.
  List<int> _deriveKeyFromPassword(String password) {
    // Salt for key derivation
    const salt = 'wallet_app_aes256_salt_v1';
    var bytes = utf8.encode('$password:$salt');

    // 10000 rounds of SHA-256 for key stretching
    for (int i = 0; i < 10000; i++) {
      bytes = Uint8List.fromList(sha256.convert(bytes).bytes);
    }

    return bytes;
  }

  /// Encrypt an image file (any format) and save it with a .enc extension.
  ///
  /// Reads the entire file as bytes, encrypts with AES-256-CBC using a
  /// random IV, and writes the result as `base64(iv):base64(ciphertext)`.
  ///
  /// Returns the path to the encrypted file, or null on failure.
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
      final iv = encrypt.IV(_generateSecureRandomBytes(16));
      final encrypter = encrypt.Encrypter(
        encrypt.AES(_encryptionKey!, mode: encrypt.AESMode.cbc),
      );
      final encrypted = encrypter.encryptBytes(imageBytes, iv: iv);

      // Store as: base64(iv):base64(ciphertext)
      final encryptedContent = '${iv.base64}:${encrypted.base64}';

      // Save encrypted file with .enc extension
      final encryptedPath = '$sourceFilePath.enc';
      final encryptedFile = File(encryptedPath);
      await encryptedFile.writeAsString(encryptedContent);

      // Delete the original unencrypted file
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

  /// Decrypt an encrypted image file and return the path to the decrypted file.
  ///
  /// Expects the format: `base64(iv):base64(ciphertext)`
  /// Returns the path to a temporary decrypted file.
  /// The caller is responsible for deleting the temporary file after use.
  Future<String?> decryptImageFile(String encryptedFilePath) async {
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
        // File is not encrypted, return as-is
        return encryptedFilePath;
      }

      final parts = content.split(':');
      final iv = encrypt.IV.fromBase64(parts[0]);
      final encryptedData = encrypt.Encrypted.fromBase64(parts[1]);

      final encrypter = encrypt.Encrypter(
        encrypt.AES(_encryptionKey!, mode: encrypt.AESMode.cbc),
      );
      final decryptedBytes = encrypter.decryptBytes(encryptedData, iv: iv);

      // Write to temporary file
      final tempDir = await _getTempDirectory();
      final originalName = encryptedFilePath.split('/').last;
      final decryptedPath = '${tempDir.path}/decrypted_$originalName';
      final decryptedFile = File(decryptedPath);
      await decryptedFile.writeAsBytes(decryptedBytes);

      debugPrint(
        'EncryptionService: Image decrypted successfully: $decryptedPath',
      );
      return decryptedPath;
    } catch (e) {
      debugPrint('EncryptionService: Image decryption failed: $e');
      throw Exception('Failed to decrypt image: $e');
    }
  }

  /// Get a temporary directory for decrypted image files.
  Future<Directory> _getTempDirectory() async {
    try {
      final tempDir = await Directory.systemTemp.createTemp('wallet_images_');
      return tempDir;
    } catch (e) {
      // Fallback to app documents directory
      final directory = await getApplicationDocumentsDirectory();
      return Directory('${directory.path}/temp_images');
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
