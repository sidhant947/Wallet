export 'wallet.dart';
export 'pass.dart';
export 'identity_card.dart';
import 'wallet.dart';
import 'pass.dart';
import 'identity_card.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'walletbox.db');
    return openDatabase(
      path,
      version: 7,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE wallets(
            id INTEGER PRIMARY KEY,
            name TEXT,
            number TEXT,
            expiry TEXT,
            network TEXT,
            issuer TEXT,
            customFields TEXT,
            spends TEXT,
            rewards TEXT,
            annualFeeWaiver TEXT,
            maxlimit TEXT,
            cardtype TEXT,
            billdate TEXT,
            category TEXT,
            color TEXT,
            frontImagePath TEXT,
            backImagePath TEXT,
            orderIndex INTEGER DEFAULT 0
          )
          ''');
        await db.execute(
          'CREATE INDEX idx_wallets_order ON wallets(orderIndex);',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE wallets ADD COLUMN spends TEXT;');
          await db.execute('ALTER TABLE wallets ADD COLUMN rewards TEXT;');
          await db.execute(
            'ALTER TABLE wallets ADD COLUMN annualFeeWaiver TEXT;',
          );
          await db.execute('ALTER TABLE wallets ADD COLUMN maxlimit TEXT;');
          await db.execute('ALTER TABLE wallets ADD COLUMN cardtype TEXT;');
          await db.execute('ALTER TABLE wallets ADD COLUMN billdate TEXT;');
          await db.execute('ALTER TABLE wallets ADD COLUMN category TEXT;');
          await db.execute('ALTER TABLE wallets ADD COLUMN network TEXT;');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE wallets ADD COLUMN issuer TEXT;');
          await db.execute('ALTER TABLE wallets ADD COLUMN customFields TEXT;');
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE wallets ADD COLUMN color TEXT;');
        }
        if (oldVersion < 5) {
          await db.execute(
            'ALTER TABLE wallets ADD COLUMN frontImagePath TEXT;',
          );
          await db.execute(
            'ALTER TABLE wallets ADD COLUMN backImagePath TEXT;',
          );
        }
        if (oldVersion < 6) {
          await db.execute(
            'ALTER TABLE wallets ADD COLUMN orderIndex INTEGER DEFAULT 0;',
          );
        }
        if (oldVersion < 7) {
          await db.execute(
            'CREATE INDEX idx_wallets_order ON wallets(orderIndex);',
          );
        }
      },
    );
  }

  Future<void> updateWalletsOrder(List<Wallet> wallets) async {
    Database db = await instance.database;
    Batch batch = db.batch();
    for (int i = 0; i < wallets.length; i++) {
      batch.update(
        'wallets',
        {'orderIndex': i},
        where: 'id = ?',
        whereArgs: [wallets[i].id],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<int> insertWallet(Wallet wallet) async {
    Database db = await instance.database;
    return await db.insert('wallets', wallet.toEncryptedMap());
  }

  Future<List<Wallet>> getWallets() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'wallets',
      orderBy: 'orderIndex ASC',
    );
    return List.generate(maps.length, (i) => Wallet.fromEncryptedMap(maps[i]));
  }

  Future<int> deleteWallet(int id) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'wallets',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return 0;

    final wallet = Wallet.fromEncryptedMap(maps[0]);

    await _deleteImageFile(wallet.frontImagePath);
    await _deleteImageFile(wallet.backImagePath);

    return await db.delete('wallets', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> _deleteImageFile(String? imagePath) async {
    if (imagePath != null && imagePath.isNotEmpty) {
      try {
        final file = File(imagePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
  }

  Future<int> updateWallet(Wallet wallet) async {
    Database db = await instance.database;
    return await db.update(
      'wallets',
      wallet.toEncryptedMap(),
      where: 'id = ?',
      whereArgs: [wallet.id],
    );
  }

  Future<void> migrateToEncrypted() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('wallets');

    for (final map in maps) {
      final wallet = Wallet.fromEncryptedMap(map);
      await db.update(
        'wallets',
        wallet.toEncryptedMap(),
        where: 'id = ?',
        whereArgs: [wallet.id],
      );
    }
  }
}

class PassDatabaseHelper {
  static final PassDatabaseHelper instance = PassDatabaseHelper._init();
  static Database? _database;
  PassDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'passes.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE passes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT,
            organizationName TEXT,
            description TEXT,
            logoText TEXT,
            backgroundColor TEXT,
            foregroundColor TEXT,
            labelColor TEXT,
            barcodeValue TEXT,
            barcodeFormat TEXT,
            barcodeAltText TEXT,
            transitType TEXT,
            relevantDate TEXT,
            frontImagePath TEXT,
            backImagePath TEXT,
            stripImagePath TEXT,
            thumbnailImagePath TEXT,
            fields TEXT,
            orderIndex INTEGER DEFAULT 0
          )
        ''');
        await db.execute('CREATE INDEX idx_passes_order ON passes(orderIndex);');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'CREATE INDEX idx_passes_order ON passes(orderIndex);',
          );
        }
      },
    );
  }

  Future<int> insertPass(Pass pass) async {
    final db = await database;
    return await db.insert('passes', pass.toEncryptedMap());
  }

  Future<List<Pass>> getAllPasses() async {
    final db = await database;
    final result = await db.query('passes', orderBy: 'orderIndex ASC');
    return result.map((e) => Pass.fromEncryptedMap(e)).toList();
  }

  Future<void> deletePass(int id) async {
    final db = await database;
    final result = await db.query('passes', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return;

    final pass = Pass.fromEncryptedMap(result[0]);

    await DatabaseHelper._deleteImageFile(pass.frontImagePath);
    await DatabaseHelper._deleteImageFile(pass.backImagePath);
    await DatabaseHelper._deleteImageFile(pass.stripImagePath);
    await DatabaseHelper._deleteImageFile(pass.thumbnailImagePath);

    await db.delete('passes', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updatePass(Pass pass) async {
    final db = await database;
    return await db.update(
      'passes',
      pass.toEncryptedMap(),
      where: 'id = ?',
      whereArgs: [pass.id],
    );
  }

  Future<void> updatePassesOrder(List<Pass> passes) async {
    final db = await database;
    Batch batch = db.batch();
    for (int i = 0; i < passes.length; i++) {
      batch.update(
        'passes',
        {'orderIndex': i},
        where: 'id = ?',
        whereArgs: [passes[i].id],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> migrateToEncrypted() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('passes');

    for (final map in maps) {
      final pass = Pass.fromEncryptedMap(map);
      await db.update(
        'passes',
        pass.toEncryptedMap(),
        where: 'id = ?',
        whereArgs: [pass.id],
      );
    }
  }
}

class IdentityDatabaseHelper {
  static final IdentityDatabaseHelper instance = IdentityDatabaseHelper._init();
  static Database? _database;
  IdentityDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'identities.db');
    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE identities(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            value TEXT,
            cardType TEXT,
            frontImagePath TEXT,
            backImagePath TEXT,
            color TEXT,
            orderIndex INTEGER DEFAULT 0
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_identities_order ON identities(orderIndex);',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE identities ADD COLUMN cardType TEXT;');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE identities ADD COLUMN color TEXT;');
        }
      },
    );
  }

  Future<int> insertIdentity(IdentityCard card) async {
    final db = await database;
    return await db.insert('identities', card.toEncryptedMap());
  }

  Future<List<IdentityCard>> getAllIdentities() async {
    final db = await database;
    final result = await db.query('identities', orderBy: 'orderIndex ASC');
    return result.map((e) => IdentityCard.fromEncryptedMap(e)).toList();
  }

  Future<void> deleteIdentity(int id) async {
    final db = await database;
    final result = await db.query(
      'identities',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return;

    final card = IdentityCard.fromEncryptedMap(result[0]);
    await DatabaseHelper._deleteImageFile(card.frontImagePath);
    await DatabaseHelper._deleteImageFile(card.backImagePath);

    await db.delete('identities', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateIdentity(IdentityCard card) async {
    final db = await database;
    return await db.update(
      'identities',
      card.toEncryptedMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<void> updateIdentitiesOrder(List<IdentityCard> cards) async {
    final db = await database;
    Batch batch = db.batch();
    for (int i = 0; i < cards.length; i++) {
      batch.update(
        'identities',
        {'orderIndex': i},
        where: 'id = ?',
        whereArgs: [cards[i].id],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> migrateToEncrypted() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('identities');

    for (final map in maps) {
      final card = IdentityCard.fromEncryptedMap(map);
      await db.update(
        'identities',
        card.toEncryptedMap(),
        where: 'id = ?',
        whereArgs: [card.id],
      );
    }
  }
}


