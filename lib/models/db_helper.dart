import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:wallet/services/encryption_service.dart';

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
      version: 6, // MODIFIED: Incremented version
      onCreate: (db, version) {
        return db.execute('''
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
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Note: This is a simple migration. For production apps, more robust migration is needed.
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
        // MODIFIED: Add image path columns on upgrade
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
    // Get wallet to retrieve image paths
    final List<Map<String, dynamic>> maps = await db.query(
      'wallets',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return 0;

    final wallet = Wallet.fromEncryptedMap(maps[0]);

    // Delete associated image files
    await _deleteImageFile(wallet.frontImagePath);
    await _deleteImageFile(wallet.backImagePath);

    return await db.delete('wallets', where: 'id = ?', whereArgs: [id]);
  }

  /// Helper method to delete an encrypted image file
  static Future<void> _deleteImageFile(String? imagePath) async {
    if (imagePath != null && imagePath.isNotEmpty) {
      try {
        final file = File(imagePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('DatabaseHelper: Failed to delete image file: $e');
      }
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

  /// Migrate existing plaintext wallet data to encrypted format.
  Future<void> migrateToEncrypted() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('wallets');

    for (final map in maps) {
      // Read current values (fromMap handles plaintext gracefully)
      final wallet = Wallet.fromMap(map);
      // Write back with encryption
      await db.update(
        'wallets',
        wallet.toEncryptedMap(),
        where: 'id = ?',
        whereArgs: [wallet.id],
      );
    }
    debugPrint(
      'DatabaseHelper: Wallet migration to encrypted format complete.',
    );
  }
}

class Wallet {
  final int? id;
  late final String name;
  late final String number;
  late final String expiry;
  final String? network;
  final String? issuer;
  final Map<String, String>? customFields;
  final String? spends;
  final String? rewards;
  final String? annualFeeWaiver;
  final String? maxlimit;
  late final String? cardtype;
  final String? billdate;
  final String? category;
  final String? color;
  // MODIFIED: Added image path fields
  final String? frontImagePath;
  final String? backImagePath;
  int orderIndex;

  Wallet({
    this.id,
    required this.name,
    required this.number,
    required this.expiry,
    this.network,
    this.issuer,
    this.customFields,
    this.spends,
    this.rewards,
    this.annualFeeWaiver,
    this.maxlimit,
    this.cardtype,
    this.billdate,
    this.category,
    this.color,
    this.frontImagePath,
    this.backImagePath,
    this.orderIndex = 0,
  });

  /// Plaintext map — used for in-memory operations and backup serialization.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'number': number,
      'expiry': expiry,
      'network': network,
      'issuer': issuer,
      'customFields': customFields != null ? jsonEncode(customFields) : null,
      'spends': spends,
      'rewards': rewards,
      'annualFeeWaiver': annualFeeWaiver,
      'maxlimit': maxlimit,
      'cardtype': cardtype,
      'billdate': billdate,
      'category': category,
      'color': color,
      'frontImagePath': frontImagePath,
      'backImagePath': backImagePath,
      'orderIndex': orderIndex,
    };
  }

  /// Encrypted map — used when writing to the database.
  /// Sensitive fields (name, number, expiry, issuer, customFields) are
  /// AES-256-CBC encrypted before storage.
  Map<String, dynamic> toEncryptedMap() {
    final enc = EncryptionService.instance;
    return {
      'id': id,
      'name': enc.encryptText(name),
      'number': enc.encryptText(number),
      'expiry': enc.encryptText(expiry),
      'network': network,
      'issuer': enc.encryptText(issuer),
      'customFields': customFields != null
          ? enc.encryptJson(customFields!.cast<String, dynamic>())
          : null,
      'spends': spends,
      'rewards': rewards,
      'annualFeeWaiver': annualFeeWaiver,
      'maxlimit': maxlimit,
      'cardtype': cardtype,
      'billdate': billdate,
      'category': category,
      'color': color,
      'frontImagePath': frontImagePath,
      'backImagePath': backImagePath,
      'orderIndex': orderIndex,
    };
  }

  /// Create a Wallet from a plaintext map (e.g. from backup restore).
  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'],
      name: map['name'],
      number: map['number'],
      expiry: map['expiry'],
      network: map['network'],
      issuer: map['issuer'],
      customFields: map['customFields'] != null
          ? Map<String, String>.from(jsonDecode(map['customFields']))
          : null,
      spends: map['spends'],
      rewards: map['rewards'],
      annualFeeWaiver: map['annualFeeWaiver'],
      maxlimit: map['maxlimit'],
      cardtype: map['cardtype'],
      billdate: map['billdate'],
      category: map['category'],
      color: map['color'],
      frontImagePath: map['frontImagePath'],
      backImagePath: map['backImagePath'],
      orderIndex: map['orderIndex'] ?? 0,
    );
  }

  /// Create a Wallet from an encrypted database row.
  /// Automatically decrypts sensitive fields.
  factory Wallet.fromEncryptedMap(Map<String, dynamic> map) {
    final enc = EncryptionService.instance;
    return Wallet(
      id: map['id'],
      name: enc.decryptText(map['name']) ?? '',
      number: enc.decryptText(map['number']) ?? '',
      expiry: enc.decryptText(map['expiry']) ?? '',
      network: map['network'],
      issuer: enc.decryptText(map['issuer']),
      customFields: map['customFields'] != null
          ? enc.decryptJsonToStringMap(map['customFields'])
          : null,
      spends: map['spends'],
      rewards: map['rewards'],
      annualFeeWaiver: map['annualFeeWaiver'],
      maxlimit: map['maxlimit'],
      cardtype: map['cardtype'],
      billdate: map['billdate'],
      category: map['category'],
      color: map['color'],
      frontImagePath: map['frontImagePath'],
      backImagePath: map['backImagePath'],
      orderIndex: map['orderIndex'] ?? 0,
    );
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
    final path = join(directory.path, 'identity.db');
    return openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE identities(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        identityName TEXT,
        identityNumber TEXT,
        color TEXT,
        frontImagePath TEXT,
        backImagePath TEXT,
        orderIndex INTEGER DEFAULT 0
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE identities ADD COLUMN color TEXT;');
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE identities ADD COLUMN frontImagePath TEXT;',
      );
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE identities ADD COLUMN orderIndex INTEGER DEFAULT 0;',
      );
    }
  }

  Future<void> updateIdentitiesOrder(List<Identity> identities) async {
    final db = await database;
    Batch batch = db.batch();
    for (int i = 0; i < identities.length; i++) {
      batch.update(
        'identities',
        {'orderIndex': i},
        where: 'id = ?',
        whereArgs: [identities[i].id],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<int> insertIdentity(Identity identity) async {
    final db = await database;
    return await db.insert('identities', identity.toEncryptedMap());
  }

  Future<List<Identity>> getAllIdentities() async {
    final db = await database;
    final result = await db.query('identities', orderBy: 'orderIndex ASC');
    return result.map((e) => Identity.fromEncryptedMap(e)).toList();
  }

  Future<void> deleteIdentity(int id) async {
    final db = await database;
    // Get identity to retrieve image paths
    final result = await db.query(
      'identities',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return;

    final identity = Identity.fromEncryptedMap(result[0]);

    // Delete associated image files
    await DatabaseHelper._deleteImageFile(identity.frontImagePath);
    await DatabaseHelper._deleteImageFile(identity.backImagePath);

    await db.delete('identities', where: 'id = ?', whereArgs: [id]);
  }

  /// Migrate existing plaintext identity data to encrypted format.
  Future<void> migrateToEncrypted() async {
    final db = await database;
    final result = await db.query('identities');
    for (final map in result) {
      final identity = Identity.fromMap(map);
      await db.update(
        'identities',
        identity.toEncryptedMap(),
        where: 'id = ?',
        whereArgs: [identity.id],
      );
    }
    debugPrint(
      'IdentityDatabaseHelper: Migration to encrypted format complete.',
    );
  }
}

class Identity {
  final int? id;
  final String identityName;
  final String identityNumber;
  final String? color;
  final String? frontImagePath;
  final String? backImagePath;
  int orderIndex;

  Identity({
    this.id,
    required this.identityName,
    required this.identityNumber,
    this.color,
    this.frontImagePath,
    this.backImagePath,
    this.orderIndex = 0,
  });

  /// Plaintext map — for backup serialization.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'identityName': identityName,
      'identityNumber': identityNumber,
      'color': color,
      'frontImagePath': frontImagePath,
      'backImagePath': backImagePath,
      'orderIndex': orderIndex,
    };
  }

  /// Encrypted map — for database storage.
  Map<String, dynamic> toEncryptedMap() {
    final enc = EncryptionService.instance;
    return {
      'id': id,
      'identityName': enc.encryptText(identityName),
      'identityNumber': enc.encryptText(identityNumber),
      'color': color,
      'frontImagePath': frontImagePath,
      'backImagePath': backImagePath,
      'orderIndex': orderIndex,
    };
  }

  /// Create from plaintext map (e.g. backup restore).
  factory Identity.fromMap(Map<String, dynamic> map) {
    return Identity(
      id: map['id'],
      identityName: map['identityName'],
      identityNumber: map['identityNumber'],
      color: map['color'],
      frontImagePath: map['frontImagePath'],
      backImagePath: map['backImagePath'],
      orderIndex: map['orderIndex'] ?? 0,
    );
  }

  /// Create from encrypted database row.
  factory Identity.fromEncryptedMap(Map<String, dynamic> map) {
    final enc = EncryptionService.instance;
    return Identity(
      id: map['id'],
      identityName: enc.decryptText(map['identityName']) ?? '',
      identityNumber: enc.decryptText(map['identityNumber']) ?? '',
      color: map['color'],
      frontImagePath: map['frontImagePath'],
      backImagePath: map['backImagePath'],
      orderIndex: map['orderIndex'] ?? 0,
    );
  }
}

class LoyaltyDatabaseHelper {
  static final LoyaltyDatabaseHelper instance = LoyaltyDatabaseHelper._init();
  static Database? _database;
  LoyaltyDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'loyalty.db');
    return openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE loyalties(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        loyaltyName TEXT,
        loyaltyNumber TEXT,
        color TEXT,
        frontImagePath TEXT,
        backImagePath TEXT,
        orderIndex INTEGER DEFAULT 0
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE loyalties ADD COLUMN color TEXT;');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE loyalties ADD COLUMN frontImagePath TEXT;');
      await db.execute('ALTER TABLE loyalties ADD COLUMN backImagePath TEXT;');
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE loyalties ADD COLUMN orderIndex INTEGER DEFAULT 0;',
      );
    }
  }

  Future<void> updateLoyaltiesOrder(List<Loyalty> loyalties) async {
    final db = await database;
    Batch batch = db.batch();
    for (int i = 0; i < loyalties.length; i++) {
      batch.update(
        'loyalties',
        {'orderIndex': i},
        where: 'id = ?',
        whereArgs: [loyalties[i].id],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<int> insertLoyalty(Loyalty loyalty) async {
    final db = await database;
    return await db.insert('loyalties', loyalty.toEncryptedMap());
  }

  Future<List<Loyalty>> getAllLoyalties() async {
    final db = await database;
    final result = await db.query('loyalties', orderBy: 'orderIndex ASC');
    return result.map((e) => Loyalty.fromEncryptedMap(e)).toList();
  }

  Future<void> deleteLoyalty(int id) async {
    final db = await database;
    // Get loyalty to retrieve image paths
    final result = await db.query(
      'loyalties',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return;

    final loyalty = Loyalty.fromEncryptedMap(result[0]);

    // Delete associated image files
    await DatabaseHelper._deleteImageFile(loyalty.frontImagePath);
    await DatabaseHelper._deleteImageFile(loyalty.backImagePath);

    await db.delete('loyalties', where: 'id = ?', whereArgs: [id]);
  }

  /// Migrate existing plaintext loyalty data to encrypted format.
  Future<void> migrateToEncrypted() async {
    final db = await database;
    final result = await db.query('loyalties');
    for (final map in result) {
      final loyalty = Loyalty.fromMap(map);
      await db.update(
        'loyalties',
        loyalty.toEncryptedMap(),
        where: 'id = ?',
        whereArgs: [loyalty.id],
      );
    }
    debugPrint(
      'LoyaltyDatabaseHelper: Migration to encrypted format complete.',
    );
  }
}

class Loyalty {
  final int? id;
  final String loyaltyName;
  final String loyaltyNumber;
  final String? color;
  final String? frontImagePath;
  final String? backImagePath;
  int orderIndex;

  Loyalty({
    this.id,
    required this.loyaltyName,
    required this.loyaltyNumber,
    this.color,
    this.frontImagePath,
    this.backImagePath,
    this.orderIndex = 0,
  });

  /// Plaintext map — for backup serialization.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'loyaltyName': loyaltyName,
      'loyaltyNumber': loyaltyNumber,
      'color': color,
      'frontImagePath': frontImagePath,
      'backImagePath': backImagePath,
      'orderIndex': orderIndex,
    };
  }

  /// Encrypted map — for database storage.
  Map<String, dynamic> toEncryptedMap() {
    final enc = EncryptionService.instance;
    return {
      'id': id,
      'loyaltyName': enc.encryptText(loyaltyName),
      'loyaltyNumber': enc.encryptText(loyaltyNumber),
      'color': color,
      'frontImagePath': frontImagePath,
      'backImagePath': backImagePath,
      'orderIndex': orderIndex,
    };
  }

  /// Create from plaintext map (e.g. backup restore).
  factory Loyalty.fromMap(Map<String, dynamic> map) {
    return Loyalty(
      id: map['id'],
      loyaltyName: map['loyaltyName'],
      loyaltyNumber: map['loyaltyNumber'],
      color: map['color'],
      frontImagePath: map['frontImagePath'],
      backImagePath: map['backImagePath'],
      orderIndex: map['orderIndex'] ?? 0,
    );
  }

  /// Create from encrypted database row.
  factory Loyalty.fromEncryptedMap(Map<String, dynamic> map) {
    final enc = EncryptionService.instance;
    return Loyalty(
      id: map['id'],
      loyaltyName: enc.decryptText(map['loyaltyName']) ?? '',
      loyaltyNumber: enc.decryptText(map['loyaltyNumber']) ?? '',
      color: map['color'],
      frontImagePath: map['frontImagePath'],
      backImagePath: map['backImagePath'],
      orderIndex: map['orderIndex'] ?? 0,
    );
  }
}
