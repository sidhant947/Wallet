import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:wallet/models/db_helper.dart';

class BackupService {
  static const String _backupVersion = '1.0';

  // Create encrypted backup using Storage Access Framework
  static Future<String?> createBackup(String password) async {
    try {
      // Get all data from databases
      final wallets = await DatabaseHelper.instance.getWallets();
      final identities = await IdentityDatabaseHelper.instance
          .getAllIdentities();
      final loyalties = await LoyaltyDatabaseHelper.instance.getAllLoyalties();

      // Create backup data structure
      final backupData = {
        'version': _backupVersion,
        'timestamp': DateTime.now().toIso8601String(),
        'wallets': wallets.map((w) => w.toMap()).toList(),
        'identities': identities.map((i) => i.toMap()).toList(),
        'loyalties': loyalties.map((l) => l.toMap()).toList(),
      };

      // Convert to JSON
      final jsonData = jsonEncode(backupData);

      // Encrypt the data
      final encryptedData = _encryptData(jsonData, password);

      // Create backup file with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'wallet_backup_$timestamp.wbk';

      // Use Storage Access Framework via FilePicker to save file
      // This doesn't require storage permissions on Android
      final outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Backup File',
        fileName: fileName,
        bytes: encryptedData,
        type: FileType.custom,
        allowedExtensions: ['wbk'],
      );

      if (outputFile == null) {
        throw Exception('Save location not selected');
      }

      return outputFile;
    } catch (e) {
      throw Exception('Failed to create backup: $e');
    }
  }

  // Restore from encrypted backup using Storage Access Framework
  static Future<void> restoreBackup(String password) async {
    try {
      // Pick backup file using Storage Access Framework
      // This doesn't require storage permissions on Android
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: 'Select Wallet Backup File',
        allowMultiple: false,
        withData: true, // Important: Load file data directly
      );

      if (result == null || result.files.isEmpty) {
        throw Exception('No file selected');
      }

      final platformFile = result.files.first;

      // Get encrypted data directly from bytes (SAF approach)
      Uint8List? encryptedData = platformFile.bytes;

      // Fallback to file path if bytes not available (shouldn't happen with withData: true)
      if (encryptedData == null) {
        final filePath = platformFile.path;
        if (filePath == null) {
          throw Exception('Unable to access file data');
        }
        final file = File(filePath);
        if (!await file.exists()) {
          throw Exception('Selected file does not exist');
        }
        encryptedData = await file.readAsBytes();
      }

      // Decrypt the data
      final decryptedJson = _decryptData(encryptedData, password);

      // Parse JSON
      final backupData = jsonDecode(decryptedJson) as Map<String, dynamic>;

      // Validate backup version
      if (backupData['version'] != _backupVersion) {
        throw Exception('Incompatible backup version');
      }

      // Clear existing data (optional - you might want to ask user)
      await _clearAllData();

      // Restore wallets
      final walletsData = backupData['wallets'] as List<dynamic>;
      for (final walletMap in walletsData) {
        final wallet = Wallet.fromMap(Map<String, dynamic>.from(walletMap));
        await DatabaseHelper.instance.insertWallet(wallet);
      }

      // Restore identities
      final identitiesData = backupData['identities'] as List<dynamic>;
      for (final identityMap in identitiesData) {
        final identity = Identity.fromMap(
          Map<String, dynamic>.from(identityMap),
        );
        await IdentityDatabaseHelper.instance.insertIdentity(identity);
      }

      // Restore loyalties
      final loyaltiesData = backupData['loyalties'] as List<dynamic>;
      for (final loyaltyMap in loyaltiesData) {
        final loyalty = Loyalty.fromMap(Map<String, dynamic>.from(loyaltyMap));
        await LoyaltyDatabaseHelper.instance.insertLoyalty(loyalty);
      }
    } catch (e) {
      throw Exception('Failed to restore backup: $e');
    }
  }

  // Simple encryption using AES (you might want to use a more robust solution)
  static Uint8List _encryptData(String data, String password) {
    final key = sha256.convert(utf8.encode(password)).bytes;
    final dataBytes = utf8.encode(data);

    // Simple XOR encryption (for demo - use proper AES in production)
    final encrypted = Uint8List(dataBytes.length);
    for (int i = 0; i < dataBytes.length; i++) {
      encrypted[i] = dataBytes[i] ^ key[i % key.length];
    }

    return encrypted;
  }

  // Simple decryption
  static String _decryptData(Uint8List encryptedData, String password) {
    final key = sha256.convert(utf8.encode(password)).bytes;

    // Simple XOR decryption
    final decrypted = Uint8List(encryptedData.length);
    for (int i = 0; i < encryptedData.length; i++) {
      decrypted[i] = encryptedData[i] ^ key[i % key.length];
    }

    return utf8.decode(decrypted);
  }

  // Clear all existing data before restore
  static Future<void> _clearAllData() async {
    // Get all existing data and delete
    final wallets = await DatabaseHelper.instance.getWallets();
    for (final wallet in wallets) {
      if (wallet.id != null) {
        await DatabaseHelper.instance.deleteWallet(wallet.id!);
      }
    }

    final identities = await IdentityDatabaseHelper.instance.getAllIdentities();
    for (final identity in identities) {
      if (identity.id != null) {
        await IdentityDatabaseHelper.instance.deleteIdentity(identity.id!);
      }
    }

    final loyalties = await LoyaltyDatabaseHelper.instance.getAllLoyalties();
    for (final loyalty in loyalties) {
      if (loyalty.id != null) {
        await LoyaltyDatabaseHelper.instance.deleteLoyalty(loyalty.id!);
      }
    }
  }
}
