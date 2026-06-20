import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wallet/models/db_helper.dart';
import 'package:wallet/services/encryption_service.dart';

class LoyaltyMigrationService {
  static Future<void> migrateFromLocalDb() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = join(directory.path, 'loyalty.db');

      final file = File(path);
      if (!await file.exists()) {
        return;
      }

      final db = await openDatabase(path, readOnly: true);

      final rows = await db.rawQuery('''
        SELECT loyaltyName, loyaltyNumber, color, frontImagePath, backImagePath, orderIndex
        FROM loyalties
        ORDER BY orderIndex ASC
      ''');

      await db.close();

      for (final row in rows) {
        final pass = Pass(
          type: 'storeCard',
          organizationName: EncryptionService.instance.decryptText(row['loyaltyName'] as String?) ?? '',
          barcodeValue: EncryptionService.instance.decryptText(row['loyaltyNumber'] as String?) ?? '',
          backgroundColor: row['color'] as String?,
          frontImagePath: row['frontImagePath'] as String?,
          backImagePath: row['backImagePath'] as String?,
          orderIndex: row['orderIndex'] as int? ?? 0,
        );
        await PassDatabaseHelper.instance.insertPass(pass);
      }

      await File(path).delete();

      debugPrint('LoyaltyMigrationService: migrated ${rows.length} loyalty cards to passes.');
    } catch (e) {
      debugPrint('LoyaltyMigrationService: migration failed: $e');
    }
  }
}