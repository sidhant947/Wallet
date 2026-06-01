import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:wallet/models/db_helper.dart';
import 'package:wallet/services/encryption_service.dart';

class BackupService {
  static const String _backupVersion = '3.0'; // Incremented version for Passes support

  static Future<String?> createBackup(String password) async {
    try {
      debugPrint("BackupService: Starting backup creation...");
      final wallets = await DatabaseHelper.instance.getWallets();
      final passes = await PassDatabaseHelper.instance.getAllPasses();

      final backupData = {
        'version': _backupVersion,
        'timestamp': DateTime.now().toIso8601String(),
        'wallets': wallets.map((w) => w.toMap()).toList(),
        'passes': passes.map((p) => p.toMap()).toList(),
      };

      debugPrint("BackupService: Encoding JSON data...");
      final String jsonString = jsonEncode(backupData);
      final jsonBytes = utf8.encode(jsonString);
      
      final archive = Archive();
      archive.addFile(ArchiveFile('data.json', jsonBytes.length, jsonBytes));

      debugPrint("BackupService: Compressing archive...");
      final zipData = ZipEncoder().encode(archive);
      
      debugPrint("BackupService: Encrypting backup (background)...");
      final encryptedData = await EncryptionService.instance.encryptForBackup(
        zipData is Uint8List ? zipData : Uint8List.fromList(zipData), 
        password
      );

      debugPrint("BackupService: Requesting file save...");
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Backup File',
        fileName: 'wallet_backup_${DateTime.now().millisecondsSinceEpoch}.wbk',
        bytes: encryptedData,
        type: FileType.custom,
        allowedExtensions: ['wbk'],
      );
      
      debugPrint("BackupService: Backup creation complete. Result: $result");
      return result;
    } catch (e, stack) {
      debugPrint("BackupService: Create failed with error: $e");
      debugPrint("Stack Trace: $stack");
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
      
      if (encryptedData == null) throw Exception('Unable to access backup file data.');

      final decryptedData = await EncryptionService.instance.decryptForBackup(encryptedData, password);
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
          if (dataFile == null) throw Exception("Invalid backup format: data.json missing.");
          
          backupData = jsonDecode(utf8.decode(dataFile.content as List<int>));
          imageFiles = archive.where((f) => f.name.startsWith('images/')).toList();
        } catch (e) {
          debugPrint("BackupService: ZIP/JSON decode failed: $e");
          throw Exception('Failed to process backup archive. It might be corrupted.');
        }
      }

      // If we got here, we have valid data. Proceed with restoration.
      await _clearAllData();

      final appDir = await getApplicationDocumentsDirectory();
      for (var imgFile in imageFiles) {
        try {
          final targetPath = p.join(appDir.path, p.basename(imgFile.name));
          await File(targetPath).writeAsBytes(imgFile.content as List<int>);
        } catch (e) {
          debugPrint("BackupService: Failed to restore image ${imgFile.name}: $e");
        }
      }

      final walletsData = backupData['wallets'] as List<dynamic>? ?? [];
      for (final w in walletsData) {
        try {
          await DatabaseHelper.instance.insertWallet(Wallet.fromMap(Map<String, dynamic>.from(w)));
        } catch (e) {
          debugPrint("BackupService: Failed to restore wallet: $e");
        }
      }

      final passesData = backupData['passes'] as List<dynamic>? ?? [];
      for (final pass in passesData) {
        try {
          await PassDatabaseHelper.instance.insertPass(Pass.fromMap(Map<String, dynamic>.from(pass)));
        } catch (e) {
          debugPrint("BackupService: Failed to restore pass: $e");
        }
      }
      
      // Legacy support for older backups
      final legacyIdentitiesData = backupData['identities'] as List<dynamic>? ?? [];
      for (final i in legacyIdentitiesData) {
         try {
           final map = Map<String, dynamic>.from(i);
           await PassDatabaseHelper.instance.insertPass(Pass(
             type: 'generic',
             organizationName: map['identityName'] ?? 'Legacy Pass',
             barcodeValue: map['identityNumber'] ?? '',
             frontImagePath: map['frontImagePath'],
             backImagePath: map['backImagePath'],
           ));
         } catch (e) {
           debugPrint("BackupService: Failed to restore legacy identity: $e");
         }
      }

      final legacyLoyaltiesData = backupData['loyalties'] as List<dynamic>? ?? [];
      for (final l in legacyLoyaltiesData) {
         try {
           final map = Map<String, dynamic>.from(l);
           await PassDatabaseHelper.instance.insertPass(Pass(
             type: 'storeCard',
             organizationName: map['loyaltyName'] ?? 'Legacy Card',
             barcodeValue: map['loyaltyNumber'] ?? '',
             frontImagePath: map['frontImagePath'],
             backImagePath: map['backImagePath'],
           ));
         } catch (e) {
           debugPrint("BackupService: Failed to restore legacy loyalty: $e");
         }
      }
    } catch (e) {
      debugPrint('BackupService: Restore failed: $e');
      rethrow;
    }
  }

  static Future<void> _clearAllData() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('wallets');
    final passDb = await PassDatabaseHelper.instance.database;
    await passDb.delete('passes');

    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(appDir.path);
    if (await dir.exists()) {
      for (var file in dir.listSync()) {
        if (file is File && (file.path.endsWith('.enc') || file.path.endsWith('.png') || file.path.endsWith('.jpg'))) {
          await file.delete();
        }
      }
    }
  }
}
