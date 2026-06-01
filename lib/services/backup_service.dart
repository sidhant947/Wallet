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
      final wallets = await DatabaseHelper.instance.getWallets();
      final passes = await PassDatabaseHelper.instance.getAllPasses();

      final backupData = {
        'version': _backupVersion,
        'timestamp': DateTime.now().toIso8601String(),
        'wallets': wallets.map((w) => w.toMap()).toList(),
        'passes': passes.map((p) => p.toMap()).toList(),
      };

      final archive = Archive();
      final jsonBytes = utf8.encode(jsonEncode(backupData));
      archive.addFile(ArchiveFile('data.json', jsonBytes.length, jsonBytes));

      final Set<String> imagePaths = {};
      for (var w in wallets) {
        if (w.frontImagePath != null) imagePaths.add(w.frontImagePath!);
        if (w.backImagePath != null) imagePaths.add(w.backImagePath!);
      }
      for (var pass in passes) {
        if (pass.frontImagePath != null) imagePaths.add(pass.frontImagePath!);
        if (pass.backImagePath != null) imagePaths.add(pass.backImagePath!);
        if (pass.stripImagePath != null) imagePaths.add(pass.stripImagePath!);
        if (pass.thumbnailImagePath != null) imagePaths.add(pass.thumbnailImagePath!);
      }

      for (String path in imagePaths) {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          archive.addFile(ArchiveFile('images/${p.basename(path)}', bytes.length, bytes));
        }
      }

      final zipData = ZipEncoder().encode(archive);
      final encryptedData = EncryptionService.instance.encryptForBackup(base64Encode(zipData), password);

      return await FilePicker.platform.saveFile(
        dialogTitle: 'Save Backup File',
        fileName: 'wallet_backup_${DateTime.now().millisecondsSinceEpoch}.wbk',
        bytes: encryptedData,
        type: FileType.custom,
        allowedExtensions: ['wbk'],
      );
    } catch (e) {
      debugPrint("BackupService: Create failed: $e");
      throw Exception('Failed to create backup: $e');
    }
  }

  static Future<void> restoreBackup(String password) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any, withData: true);
      if (result == null || result.files.isEmpty) throw Exception('No file selected');

      final platformFile = result.files.first;
      Uint8List? encryptedData = platformFile.bytes ?? (platformFile.path != null ? await File(platformFile.path!).readAsBytes() : null);
      if (encryptedData == null) throw Exception('Unable to access file data');

      final decryptedContent = EncryptionService.instance.decryptForBackup(encryptedData, password);
      Map<String, dynamic> backupData;
      List<ArchiveFile> imageFiles = [];

      if (decryptedContent.startsWith('{')) {
        backupData = jsonDecode(decryptedContent);
      } else {
        final zipBytes = base64Decode(decryptedContent);
        final archive = ZipDecoder().decodeBytes(zipBytes);
        final dataFile = archive.findFile('data.json');
        if (dataFile == null) throw Exception("Invalid backup: data.json missing");
        backupData = jsonDecode(utf8.decode(dataFile.content as List<int>));
        imageFiles = archive.where((f) => f.name.startsWith('images/')).toList();
      }

      await _clearAllData();

      final appDir = await getApplicationDocumentsDirectory();
      for (var imgFile in imageFiles) {
        await File(p.join(appDir.path, p.basename(imgFile.name))).writeAsBytes(imgFile.content as List<int>);
      }

      final walletsData = backupData['wallets'] as List<dynamic>? ?? [];
      for (final w in walletsData) {
        await DatabaseHelper.instance.insertWallet(Wallet.fromMap(Map<String, dynamic>.from(w)));
      }

      final passesData = backupData['passes'] as List<dynamic>? ?? [];
      for (final pass in passesData) {
        await PassDatabaseHelper.instance.insertPass(Pass.fromMap(Map<String, dynamic>.from(pass)));
      }
      
      // Legacy support for older backups
      final identitiesData = backupData['identities'] as List<dynamic>? ?? [];
      for (final i in identitiesData) {
         final map = Map<String, dynamic>.from(i);
         await PassDatabaseHelper.instance.insertPass(Pass(
           type: 'generic',
           organizationName: map['identityName'] ?? 'Identity',
           barcodeValue: map['identityNumber'] ?? '',
           frontImagePath: map['frontImagePath'],
           backImagePath: map['backImagePath'],
         ));
      }

      final loyaltiesData = backupData['loyalties'] as List<dynamic>? ?? [];
      for (final l in loyaltiesData) {
         final map = Map<String, dynamic>.from(l);
         await PassDatabaseHelper.instance.insertPass(Pass(
           type: 'storeCard',
           organizationName: map['loyaltyName'] ?? 'Loyalty',
           barcodeValue: map['loyaltyNumber'] ?? '',
           description: map['balance'],
           frontImagePath: map['frontImagePath'],
           backImagePath: map['backImagePath'],
         ));
      }

    } catch (e) {
      debugPrint('BackupService: Restore failed: $e');
      throw Exception('Failed to restore backup: $e');
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
