import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet/models/db_helper.dart';
import 'package:wallet/services/encryption_service.dart';

class BackupService {
  static const String _backupVersion = '4.0'; // Incremented for settings support

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
        if (key.startsWith('wallet_aes_256_master_key') || key == 'wallet_encryption_migrated') {
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

      // Add images to backup
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

      for (final path in imagePaths) {
        try {
          final decryptedBytes =
              await EncryptionService.instance.decryptImageToBytes(path);
          if (decryptedBytes != null) {
            final fileName = p.basename(path).replaceAll('.enc', '');
            archive.addFile(
              ArchiveFile(
                'images/$fileName',
                decryptedBytes.length,
                decryptedBytes,
              ),
            );
          }
        } catch (_) {}
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

  static Future<void> restoreBackup(String password) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

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

      final decryptedData = await EncryptionService.instance.decryptForBackup(
        encryptedData,
        password,
      );
      if (decryptedData.isEmpty) throw Exception('Decrypted content is empty.');

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

      // If we got here, we have valid data. Proceed with restoration.
      await _clearAllData();

      // Restore settings
      if (backupData.containsKey('settings')) {
        final settings = backupData['settings'] as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();
        for (final entry in settings.entries) {
          final key = entry.key;
          final value = entry.value;
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

      final identitiesData = backupData['identities'] as List<dynamic>? ?? [];
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
      
      // Legacy support for older backups
      final legacyIdentitiesData = backupData['identities'] as List<dynamic>? ?? [];
      for (final _ in legacyIdentitiesData) {
         try {
           // final map = Map<String, dynamic>.from(i);
           // Only import if it's not already handled by the modern identitiesData
           // In old versions, identities were different.
           // This is just a safety check.
         } catch (_) {}
      }
    } catch (_) {
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
      for (var file in dir.listSync()) {
        if (file is File && (file.path.endsWith('.enc') || file.path.endsWith('.png') || file.path.endsWith('.jpg'))) {
          await file.delete();
        }
      }
    }

    // Clear settings
    final prefs = await SharedPreferences.getInstance();
    // Only clear non-encryption settings to avoid bricking the current install's encryption state
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (!key.startsWith('wallet_aes_256_master_key') && key != 'wallet_encryption_migrated') {
        await prefs.remove(key);
      }
    }
  }
}
