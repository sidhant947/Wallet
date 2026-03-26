import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
      debugPrint('EncryptionService: Initialization failed: $e');
      // Fallback — derive a key from a fixed seed so the app doesn't crash.
      // This is less secure but keeps the app functional.
      final fallbackBytes = sha256
          .convert(utf8.encode('wallet_fallback_key_seed'))
          .bytes;
      _encryptionKey = encrypt.Key(Uint8List.fromList(fallbackBytes));
      _isInitialized = true;
      debugPrint('EncryptionService: Using fallback key.');
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
  String? encryptText(String? plaintext) {
    if (plaintext == null || plaintext.isEmpty) return plaintext;
    if (!_isInitialized || _encryptionKey == null) {
      debugPrint('EncryptionService: Not initialized, returning plaintext.');
      return plaintext;
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
      return plaintext; // Fallback to plaintext on error
    }
  }

  /// Decrypt an encrypted string (format: `base64(iv):base64(ciphertext)`).
  ///
  /// If the input doesn't look like an encrypted value (no `:` separator),
  /// it's returned as-is — this supports transparent migration of
  /// existing plaintext data.
  String? decryptText(String? ciphertext) {
    if (ciphertext == null || ciphertext.isEmpty) return ciphertext;
    if (!_isInitialized || _encryptionKey == null) {
      debugPrint('EncryptionService: Not initialized, returning ciphertext.');
      return ciphertext;
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
      // If decryption fails, it might be plaintext data — return as-is
      return ciphertext;
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
  /// Uses PBKDF2-like key derivation from the password.
  Uint8List encryptForBackup(String data, String password) {
    final keyBytes = _deriveKeyFromPassword(password);
    final key = encrypt.Key(Uint8List.fromList(keyBytes));
    final iv = encrypt.IV(_generateSecureRandomBytes(16));

    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc),
    );
    final encrypted = encrypter.encrypt(data, iv: iv);

    // Prepend the IV to the ciphertext (first 16 bytes = IV)
    final result = Uint8List(16 + encrypted.bytes.length);
    result.setRange(0, 16, iv.bytes);
    result.setRange(16, result.length, encrypted.bytes);
    return result;
  }

  /// Decrypt backup data using AES-256-CBC with a password-derived key.
  String decryptForBackup(Uint8List encryptedData, String password) {
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

  /// Derive a 256-bit key from a password using multiple rounds of SHA-256.
  /// This is a simplified PBKDF2-like derivation.
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
