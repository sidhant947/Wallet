import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wallet/models/db_helper.dart';
import 'package:wallet/services/encryption_service.dart';

class AppInitializationService {
  /// Handles all critical app initialization logic including database setup and encryption.
  static Future<void> initializeApp() async {
    // This is for desktop/testing Only
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      databaseFactory = databaseFactoryFfi;
    }

    // Initialize AES-256 encryption service BEFORE any database operations.
    await EncryptionService.instance.init();

    await Future.wait([
      DatabaseHelper.instance.database,
      PassDatabaseHelper.instance.database,
      IdentityDatabaseHelper.instance.database,
    ]);

    // One-time migration: encrypt any existing plaintext data in the databases.
    if (!await EncryptionService.instance.isMigrated()) {
      await Future.wait([
        DatabaseHelper.instance.migrateToEncrypted(),
        PassDatabaseHelper.instance.migrateToEncrypted(),
        IdentityDatabaseHelper.instance.migrateToEncrypted(),
      ]);
      await EncryptionService.instance.markMigrated();
    }
  }
}
