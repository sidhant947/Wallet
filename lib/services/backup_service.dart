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
  static const String _backupVersion = '2.0'; // Incremented version for ZIP format

  // Create encrypted backup using Storage Access Framework
  static Future<String?> createBackup(String password) async {
    try {
      // 1. Get all data from databases
      final wallets = await DatabaseHelper.instance.getWallets();
      final identities = await IdentityDatabaseHelper.instance.getAllIdentities();
      final loyalties = await LoyaltyDatabaseHelper.instance.getAllLoyalties();

      final backupData = {
        'version': _backupVersion,
        'timestamp': DateTime.now().toIso8601String(),
        'wallets': wallets.map((w) => w.toMap()).toList(),
        'identities': identities.map((i) => i.toMap()).toList(),
        'loyalties': loyalties.map((l) => l.toMap()).toList(),
      };

      final jsonData = jsonEncode(backupData);

      // 2. Create a ZIP archive to hold JSON and Images
      final archive = Archive();

      // Add JSON data
      final jsonBytes = utf8.encode(jsonData);
      archive.addFile(ArchiveFile('data.json', jsonBytes.length, jsonBytes));

      // 3. Find and add all encrypted image files
      final Set<String> imagePaths = {};
      for (var w in wallets) {
        if (w.frontImagePath != null) imagePaths.add(w.frontImagePath!);
        if (w.backImagePath != null) imagePaths.add(w.backImagePath!);
      }
      for (var i in identities) {
        if (i.frontImagePath != null) imagePaths.add(i.frontImagePath!);
        if (i.backImagePath != null) imagePaths.add(i.backImagePath!);
      }
      for (var l in loyalties) {
        if (l.frontImagePath != null) imagePaths.add(l.frontImagePath!);
        if (l.backImagePath != null) imagePaths.add(l.backImagePath!);
      }

      for (String path in imagePaths) {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final fileName = p.basename(path);
          archive.addFile(ArchiveFile('images/$fileName', bytes.length, bytes));
        }
      }

      // 4. Encode ZIP and then ENCRYPT the whole ZIP
      final zipData = ZipEncoder().encode(archive);

      // Encrypt using AES-256-GCM
      final encryptedData = EncryptionService.instance.encryptForBackup(
        base64Encode(zipData), // Using base64 to ensure it handles binary via existing text-based method
        password,
      );

      // 5. Save the file
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'wallet_backup_$timestamp.wbk';

      final outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Backup File',
        fileName: fileName,
        bytes: encryptedData,
        type: FileType.custom,
        allowedExtensions: ['wbk'],
      );

      return outputFile;
    } catch (e) {
      debugPrint("BackupService: Create failed: $e");
      throw Exception('Failed to create backup: $e');
    }
  }

  // Restore from encrypted backup using Storage Access Framework
  static Future<void> restoreBackup(String password) async {
    final List<Wallet> backupWallets = await DatabaseHelper.instance.getWallets();
    final List<Identity> backupIdentities = await IdentityDatabaseHelper.instance.getAllIdentities();
    final List<Loyalty> backupLoyalties = await LoyaltyDatabaseHelper.instance.getAllLoyalties();

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: 'Select Wallet Backup File',
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) throw Exception('No file selected');

      final platformFile = result.files.first;
      Uint8List? encryptedData = platformFile.bytes;

      if (encryptedData == null && platformFile.path != null) {
        encryptedData = await File(platformFile.path!).readAsBytes();
      }
      if (encryptedData == null) throw Exception('Unable to access file data');

      // 1. Decrypt
      final decryptedContent = EncryptionService.instance.decryptForBackup(
        encryptedData,
        password,
      );

      Map<String, dynamic> backupData;
      List<ArchiveFile> imageFiles = [];

      // Detect if it's a legacy JSON backup or a new ZIP backup
      if (decryptedContent.startsWith('{')) {
        // Legacy JSON format
        backupData = jsonDecode(decryptedContent);
      } else {
        // New ZIP format (base64 encoded ZIP)
        final zipBytes = base64Decode(decryptedContent);
        final archive = ZipDecoder().decodeBytes(zipBytes);
        
        final dataFile = archive.findFile('data.json');
        if (dataFile == null) throw Exception("Invalid backup: data.json missing");
        
        backupData = jsonDecode(utf8.decode(dataFile.content as List<int>));
        imageFiles = archive.where((f) => f.name.startsWith('images/')).toList();
      }

      // 2. Clear existing data (including images)
      await _clearAllData();

      // 3. Restore Images first (if any)
      final appDir = await getApplicationDocumentsDirectory();
      for (var imgFile in imageFiles) {
        final fileName = p.basename(imgFile.name);
        final destPath = p.join(appDir.path, fileName);
        await File(destPath).writeAsBytes(imgFile.content as List<int>);
      }

      // 4. Restore Database Records
      final walletsData = backupData['wallets'] as List<dynamic>;
      for (final walletMap in walletsData) {
        await DatabaseHelper.instance.insertWallet(Wallet.fromMap(Map<String, dynamic>.from(walletMap)));
      }

      final identitiesData = backupData['identities'] as List<dynamic>;
      for (final identityMap in identitiesData) {
        await IdentityDatabaseHelper.instance.insertIdentity(Identity.fromMap(Map<String, dynamic>.from(identityMap)));
      }

      final loyaltiesData = backupData['loyalties'] as List<dynamic>;
      for (final loyaltyMap in loyaltiesData) {
        await LoyaltyDatabaseHelper.instance.insertLoyalty(Loyalty.fromMap(Map<String, dynamic>.from(loyaltyMap)));
      }

    } catch (e) {
      debugPrint('BackupService: Restore failed, rolling back...: $e');
      // Simple rollback logic
      await _clearAllData();
      for (var w in backupWallets) {
        await DatabaseHelper.instance.insertWallet(w);
      }
      for (var i in backupIdentities) {
        await IdentityDatabaseHelper.instance.insertIdentity(i);
      }
      for (var l in backupLoyalties) {
        await LoyaltyDatabaseHelper.instance.insertLoyalty(l);
      }
      throw Exception('Failed to restore backup: $e');
    }
  }

  // Clear all existing data before restore
  static Future<void> _clearAllData() async {
    // Clear databases
    final db = await DatabaseHelper.instance.database;
    await db.delete('wallets');
    final identityDb = await IdentityDatabaseHelper.instance.database;
    await identityDb.delete('identities');
    final loyaltyDb = await LoyaltyDatabaseHelper.instance.database;
    await loyaltyDb.delete('loyalties');

    // Clear all .enc image files to prevent orphaning
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(appDir.path);
    if (await dir.exists()) {
      final files = dir.listSync();
      for (var file in files) {
        if (file is File && file.path.endsWith('.enc')) {
          await file.delete();
        }
      }
    }
  }
}
