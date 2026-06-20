import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet/models/db_helper.dart';
import 'package:wallet/services/encryption_service.dart';

class BackupService {
  static const String _backupVersion = '4.0'; // Incremented for settings support
  static const int _maxDecompressedSize = 100 * 1024 * 1024; // 100MB zip bomb limit

  static const Set<String> _allowedSettingsKeys = {
    'themePreference',
    'useSystemFont',
    'showAuthenticationScreen',
    'defaultScreenIndex',
    'paymentsOnlyMode',
    'hideIdentityAndLoyalty',
    'selectedCurrencyCode',
    'selectedCurrencySymbol',
  };

  static bool _isAllowedSettingsKey(String key) {
    return _allowedSettingsKeys.contains(key);
  }

  static Future<String?> createBackup(String password) async {
    try {
      final wallets = await DatabaseHelper.instance.getWallets();
      final passes = await PassDatabaseHelper.instance.getAllPasses();
      final identities = await IdentityDatabaseHelper.instance.getAllIdentities();
      
      // Fetch settings from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final settings = <String, dynamic>{};
      final keys = prefs.getKeys();
      for (final key in keys) {
        // DO NOT backup encryption keys or migration flags
        if (key.startsWith('wallet_aes_256_master_key') ||
            key == 'wallet_encryption_migrated' ||
            key == 'wallet_encryption_migrated_v2' ||
            key == 'wallet_transfer_key') {
          continue;
        }
        settings[key] = prefs.get(key);
      }

      final backupData = {
        'version': _backupVersion,
        'timestamp': DateTime.now().toIso8601String(),
        'wallets': wallets.map((w) => w.toMap()).toList(),
        'passes': passes.map((p) => p.toMap()).toList(),
        'identities': identities.map((i) => i.toMap()).toList(),
        'settings': settings,
      };

      final String jsonString = jsonEncode(backupData);
      final jsonBytes = utf8.encode(jsonString);

      final archive = Archive();
      archive.addFile(ArchiveFile('data.json', jsonBytes.length, jsonBytes));

      // Add images to backup — decrypt all in parallel
      final imagePaths = <String>{};
      for (final w in wallets) {
        if (w.frontImagePath != null) imagePaths.add(w.frontImagePath!);
        if (w.backImagePath != null) imagePaths.add(w.backImagePath!);
      }
      for (final p in passes) {
        if (p.frontImagePath != null) imagePaths.add(p.frontImagePath!);
        if (p.backImagePath != null) imagePaths.add(p.backImagePath!);
        if (p.stripImagePath != null) imagePaths.add(p.stripImagePath!);
        if (p.thumbnailImagePath != null) imagePaths.add(p.thumbnailImagePath!);
      }
      for (final i in identities) {
        if (i.frontImagePath != null) imagePaths.add(i.frontImagePath!);
        if (i.backImagePath != null) imagePaths.add(i.backImagePath!);
      }

      final imageFutures = imagePaths.map((path) async {
        try {
          final decryptedBytes =
              await EncryptionService.instance.decryptImageToBytes(path);
          if (decryptedBytes != null) {
            final fileName = p.basename(path).replaceAll('.enc', '');
            return ArchiveFile(
              'images/$fileName',
              decryptedBytes.length,
              decryptedBytes,
            );
          }
        } catch (_) {}
        return null;
      }).toList();

      final imageResults = await Future.wait(imageFutures);
      for (final file in imageResults) {
        if (file != null) archive.addFile(file);
      }

      final zipData = ZipEncoder().encode(archive);

      final encryptedData = await EncryptionService.instance.encryptForBackup(
        Uint8List.fromList(zipData),
        password,
      );

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Backup File',
        fileName: 'wallet_backup_${DateTime.now().millisecondsSinceEpoch}.wbk',
        bytes: encryptedData,
        type: FileType.custom,
        allowedExtensions: ['wbk'],
      );

      return result;
    } catch (_) {
      rethrow;
    }
  }

  static Future<void> restoreBackup(String password, {BuildContext? context}) async {
    // Optional UI hooks for granular progress reporting. Caller may pass null.
    void toast(String message, {bool isError = false}) {
      debugPrint('BackupService: $message');
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      toast('Reading backup file...');
      final platformFile = result.files.first;
      Uint8List? encryptedData = platformFile.bytes;

      if (encryptedData == null && platformFile.path != null) {
        final file = File(platformFile.path!);
        if (await file.exists()) {
          encryptedData = await file.readAsBytes();
        }
      }

      if (encryptedData == null) {
        throw Exception('Unable to access backup file data.');
      }

      // Pre-validate the encrypted payload BEFORE attempting decryption.
      // This catches the common user error of picking the wrong file (a photo,
      // a zip, etc.) and turns it into an actionable message instead of the
      // generic "Invalid password or corrupted backup file" coming from the
      // crypto layer.
      _validateBackupFileShape(encryptedData);

      final decryptedData = await EncryptionService.instance.decryptForBackup(
        encryptedData,
        password,
      );
      if (decryptedData.isEmpty) throw Exception('Decrypted content is empty.');
      toast('Backup decrypted successfully.');

      Map<String, dynamic> backupData;
      List<ArchiveFile> imageFiles = [];

      // Try to see if it's a legacy JSON-only backup string
      String? decryptedString;
      try {
        decryptedString = utf8.decode(decryptedData);
      } catch (_) {
        // Not a UTF-8 string, definitely a ZIP archive
      }

      if (decryptedString != null && decryptedString.startsWith('{')) {
        // Legacy JSON-only backup
        try {
          backupData = jsonDecode(decryptedString);
        } catch (e) {
          throw Exception('Failed to parse backup data: Malformed JSON.');
        }
      } else {
        // Modern ZIP-based backup (or older ZIP-in-base64 format)
        try {
          // Reject obviously oversized encrypted data before attempting decompression
          if (decryptedData.length > _maxDecompressedSize) {
            throw Exception('Backup file is too large.');
          }

          Archive? archive;
          try {
            // First try direct ZIP decode
            archive = ZipDecoder().decodeBytes(decryptedData);
          } catch (_) {
            // If that fails, it might be the intermediate base64-in-string format
            if (decryptedString != null) {
              final zipBytes = base64Decode(decryptedString);
              archive = ZipDecoder().decodeBytes(zipBytes);
            }
          }

          if (archive == null) throw Exception("Could not decode backup archive.");

          // Zip bomb protection: check decompressed size
          int totalSize = 0;
          for (final file in archive) {
            totalSize += file.size;
            if (totalSize > _maxDecompressedSize) {
              throw Exception('Backup archive exceeds maximum allowed size.');
            }
          }

          final dataFile = archive.findFile('data.json');
          if (dataFile == null) {
            throw Exception("Invalid backup format: data.json missing.");
          }

          backupData = jsonDecode(utf8.decode(dataFile.content as List<int>));
          imageFiles =
              archive.where((f) => f.name.startsWith('images/')).toList();
        } catch (_) {
          throw Exception(
            'Failed to process backup archive. It might be corrupted.',
          );
        }
      }

      // Validate backup data schema
      if (!_isValidBackupSchema(backupData)) {
        throw Exception('Backup file has an invalid or unsupported format.');
      }
      toast('Backup validated. Clearing current data...');

      // If we got here, we have valid data. Proceed with restoration.
      await _clearAllData();
      toast('Current data cleared. Starting restoration...');

      // Restore settings
      toast('Restoring settings...');
      if (backupData.containsKey('settings')) {
        final settings = backupData['settings'] as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();
        for (final entry in settings.entries) {
          final key = entry.key;
          final value = entry.value;
          if (_isAllowedSettingsKey(key)) {
            if (value is bool) {
              await prefs.setBool(key, value);
            } else if (value is int) {
              await prefs.setInt(key, value);
            } else if (value is double) {
              await prefs.setDouble(key, value);
            } else if (value is String) {
              await prefs.setString(key, value);
            } else if (value is List) {
              await prefs.setStringList(key, List<String>.from(value));
            }
          }
        }
      }

      toast('Extracting images from archive...');
      final appDir = await getApplicationDocumentsDirectory();
      final Map<String, String> oldToNewImagePaths = {};

      for (var imgFile in imageFiles) {
        try {
          final fileName = p.basename(imgFile.name);
          final tempPath = p.join(appDir.path, 'temp_$fileName');
          final tempFile = File(tempPath);
          await tempFile.writeAsBytes(imgFile.content as List<int>);

          // Re-encrypt image with the new master key
          final encryptedPath = await EncryptionService.instance
              .encryptImageFile(tempPath);

          if (encryptedPath != null) {
            // Store mapping to update DB paths if they changed (e.g. extension added)
            // But usually we want to keep the filename from backupData
            oldToNewImagePaths[fileName] = encryptedPath;
            // The original .enc was removed by encryptImageFile, so we are good.
          }
        } catch (_) {}
      }

      final walletsData = backupData['wallets'] as List<dynamic>? ?? [];
      toast('Restoring wallets (${walletsData.length})...');
      for (final w in walletsData) {
        try {
          final walletMap = Map<String, dynamic>.from(w);

          // Update image paths if they were re-encrypted to a different filename/extension
          if (walletMap['frontImagePath'] != null) {
            final oldName = p.basename(walletMap['frontImagePath']).replaceAll(
              '.enc',
              '',
            );
            if (oldToNewImagePaths.containsKey(oldName)) {
              walletMap['frontImagePath'] = oldToNewImagePaths[oldName];
            }
          }
          if (walletMap['backImagePath'] != null) {
            final oldName = p.basename(walletMap['backImagePath']).replaceAll(
              '.enc',
              '',
            );
            if (oldToNewImagePaths.containsKey(oldName)) {
              walletMap['backImagePath'] = oldToNewImagePaths[oldName];
            }
          }

          await DatabaseHelper.instance.insertWallet(Wallet.fromMap(walletMap));
        } catch (_) {}
      }

      final passesData = backupData['passes'] as List<dynamic>? ?? [];
      toast('Restoring passes (${passesData.length})...');
      for (final pass in passesData) {
        try {
          final passMap = Map<String, dynamic>.from(pass);

          // Update image paths
          final imageFields = [
            'frontImagePath',
            'backImagePath',
            'stripImagePath',
            'thumbnailImagePath',
          ];
          for (final field in imageFields) {
            if (passMap[field] != null) {
              final oldName = p.basename(passMap[field]).replaceAll('.enc', '');
              if (oldToNewImagePaths.containsKey(oldName)) {
                passMap[field] = oldToNewImagePaths[oldName];
              }
            }
          }

          await PassDatabaseHelper.instance.insertPass(Pass.fromMap(passMap));
        } catch (_) {}
      }

      // Legacy support: old backups stored loyalty cards under a 'loyalties' key.
      // Convert each to a storeCard Pass so users keep their data after upgrading.
      debugPrint('BackupService: entering legacy loyalty migration');
      List<dynamic> loyaltiesData;
      try {
        loyaltiesData = (backupData['loyalties'] as List<dynamic>?) ?? [];
      } catch (e) {
        debugPrint('BackupService: failed to read loyalties array: $e');
        loyaltiesData = [];
      }
      debugPrint('BackupService: found ${loyaltiesData.length} loyalty entries to migrate');

      String? remapImagePath(String? path) {
        if (path == null || path.isEmpty) return path;
        final oldName = p.basename(path).replaceAll('.enc', '');
        return oldToNewImagePaths[oldName] ?? path;
      }

      for (int i = 0; i < loyaltiesData.length; i++) {
        final loyalty = loyaltiesData[i];
        try {
          // Skip non-Map entries (corrupted backup or unexpected shape).
          if (loyalty is! Map) {
            debugPrint('BackupService: loyalty[$i] is ${loyalty.runtimeType}, skipping');
            continue;
          }
          final lm = Map<String, dynamic>.from(loyalty);

          // Defensive: coerce every string field via toString() so non-String JSON
          // values (numbers, booleans, nested maps) don't trip Pass.fromMap's
          // required-String checks. Defensive: int.tryParse so a string-encoded
          // orderIndex from a partial backup doesn't throw.
          final passMap = <String, dynamic>{
            'type': 'storeCard',
            'organizationName': lm['loyaltyName']?.toString() ?? '',
            'barcodeValue': lm['loyaltyNumber']?.toString() ?? '',
            'backgroundColor': lm['color']?.toString(),
            'frontImagePath': remapImagePath(lm['frontImagePath']?.toString()),
            'backImagePath': remapImagePath(lm['backImagePath']?.toString()),
            'orderIndex': int.tryParse(lm['orderIndex']?.toString() ?? '') ?? 0,
          };

          await PassDatabaseHelper.instance.insertPass(Pass.fromMap(passMap));
        } catch (e, st) {
          debugPrint('BackupService: failed to migrate loyalty[$i]: $e\n$st');
        }
      }
      debugPrint('BackupService: legacy loyalty migration complete');

      final identitiesData = backupData['identities'] as List<dynamic>? ?? [];
      toast('Restoring identities (${identitiesData.length})...');
      for (final i in identitiesData) {
        try {
          final identityMap = Map<String, dynamic>.from(i);

          if (identityMap['frontImagePath'] != null) {
            final oldName = p.basename(identityMap['frontImagePath']).replaceAll('.enc', '');
            if (oldToNewImagePaths.containsKey(oldName)) {
              identityMap['frontImagePath'] = oldToNewImagePaths[oldName];
            }
          }
          if (identityMap['backImagePath'] != null) {
            final oldName = p.basename(identityMap['backImagePath']).replaceAll('.enc', '');
            if (oldToNewImagePaths.containsKey(oldName)) {
              identityMap['backImagePath'] = oldToNewImagePaths[oldName];
            }
          }

          await IdentityDatabaseHelper.instance.insertIdentity(IdentityCard.fromMap(identityMap));
        } catch (_) {}
      }
      toast('Restore complete!');
    } catch (e, st) {
      final msg = 'Restore failed: $e';
      debugPrint('BackupService: $msg');
      debugPrint('Stack trace: $st');
      toast(msg, isError: true);
      rethrow;
    }
  }

  static Future<void> _clearAllData() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('wallets');
    final passDb = await PassDatabaseHelper.instance.database;
    await passDb.delete('passes');
    final identityDb = await IdentityDatabaseHelper.instance.database;
    await identityDb.delete('identities');

    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(appDir.path);
    if (await dir.exists()) {
      final deleteFutures = <Future>[];
      for (var file in dir.listSync()) {
        if (file is File && _isAppSpecificFile(file.path)) {
          deleteFutures.add(file.delete());
        }
      }
      if (deleteFutures.isNotEmpty) {
        await Future.wait(deleteFutures);
      }
    }

    // Clear settings
    final prefs = await SharedPreferences.getInstance();
    // Only clear non-encryption settings to avoid bricking the current install's encryption state
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (!key.startsWith('wallet_aes_256_master_key') &&
          key != 'wallet_encryption_migrated' &&
          key != 'wallet_encryption_migrated_v2' &&
          key != 'wallet_transfer_key') {
        await prefs.remove(key);
      }
    }
  }

  static bool _isAppSpecificFile(String path) {
    final basename = path.split(Platform.pathSeparator).last;
    if (basename.endsWith('.enc')) return true;
    if (basename.endsWith('.png') || basename.endsWith('.jpg')) {
      // Only delete files with timestamp-based names from image_service
      return RegExp(r'^\d{16,}\.(png|jpg)$').hasMatch(basename);
    }
    return false;
  }

  static bool _isValidBackupSchema(Map<String, dynamic> data) {
    if (data.isEmpty) return false;
    // Must have at least one data array
    final hasWallets = data.containsKey('wallets') && data['wallets'] is List;
    final hasPasses = data.containsKey('passes') && data['passes'] is List;
    final hasIdentities = data.containsKey('identities') && data['identities'] is List;
    final hasLoyalties = data.containsKey('loyalties') && data['loyalties'] is List;
    if (!hasWallets && !hasPasses && !hasIdentities && !hasLoyalties) return false;
    // Validate wallet entries have required fields
    if (hasWallets) {
      for (final w in data['wallets'] as List) {
        if (w is! Map<String, dynamic>) return false;
        if (!w.containsKey('name') || !w.containsKey('number') || !w.containsKey('expiry')) return false;
      }
    }
    // Validate pass entries
    if (hasPasses) {
      for (final p in data['passes'] as List) {
        if (p is! Map<String, dynamic>) return false;
        if (!p.containsKey('type') || !p.containsKey('organizationName') || !p.containsKey('barcodeValue')) return false;
      }
    }
    // Validate identity entries
    if (hasIdentities) {
      for (final i in data['identities'] as List) {
        if (i is! Map<String, dynamic>) return false;
        if (!i.containsKey('name') || !i.containsKey('value')) return false;
      }
    }
    return true;
  }

  /// Reject obviously-wrong files (photos, archives, etc.) before we burn the
  /// ~1–2 seconds of PBKDF2 work that [decryptForBackup] will do, and so the
  /// user gets a clear "wrong file" message instead of a misleading
  /// "invalid password" error from the crypto layer.
  ///
  /// NOTE: this is intentionally permissive. A current-format encrypted
  /// backup is the UTF-8 string `base64(salt):base64(iv):base64(ciphertext+tag)`,
  /// but the app also supports a legacy raw-binary format (no colons, just
  /// 16-byte IV + ciphertext). So we only reject signatures that no real
  /// wallet backup could ever start with.
  static void _validateBackupFileShape(Uint8List data) {
    if (data.length < 64) {
      throw Exception(
        'Selected file is too small to be a wallet backup '
        '(${data.length} bytes). Please pick the .wbk file created by this app.',
      );
    }

    // Reject common binary headers that the user might have picked by mistake.
    // Each list is a known magic number for a popular file format. We deliberately
    // do NOT include the very first byte alone (e.g. raw legacy backups can start
    // with any byte), only multi-byte signatures that are unambiguous.
    const binarySignatures = <String, List<int>>{
      'PNG image': [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
      'JPEG image': [0xFF, 0xD8, 0xFF],
      'GIF87a image': [0x47, 0x49, 0x46, 0x38, 0x37, 0x61],
      'GIF89a image': [0x47, 0x49, 0x46, 0x38, 0x39, 0x61],
      'ZIP archive (also .jar/.docx/.apk)': [0x50, 0x4B, 0x03, 0x04],
      'GZIP': [0x1F, 0x8B],
      'PDF document': [0x25, 0x50, 0x44, 0x46],
      'MP4/MOV video': [0x00, 0x00, 0x00, 0x18, 0x66, 0x74, 0x79, 0x70],
    };
    for (final entry in binarySignatures.entries) {
      final sig = entry.value;
      if (data.length >= sig.length) {
        var match = true;
        for (var i = 0; i < sig.length; i++) {
          if (data[i] != sig[i]) {
            match = false;
            break;
          }
        }
        if (match) {
          throw Exception(
            'Selected file looks like a ${entry.key}, not a wallet backup. '
            'Please pick the .wbk file created by this app.',
          );
        }
      }
    }
  }
}
