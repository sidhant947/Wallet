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
      version: 6,
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
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE wallets ADD COLUMN spends TEXT;');
          await db.execute('ALTER TABLE wallets ADD COLUMN rewards TEXT;');
          await db.execute('ALTER TABLE wallets ADD COLUMN annualFeeWaiver TEXT;');
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
          await db.execute('ALTER TABLE wallets ADD COLUMN frontImagePath TEXT;');
          await db.execute('ALTER TABLE wallets ADD COLUMN backImagePath TEXT;');
        }
        if (oldVersion < 6) {
          await db.execute('ALTER TABLE wallets ADD COLUMN orderIndex INTEGER DEFAULT 0;');
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
    debugPrint('DatabaseHelper: Wallet migration to encrypted format complete.');
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
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
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
    debugPrint('PassDatabaseHelper: Pass migration to encrypted format complete.');
  }
}

class Pass {
  final int? id;
  final String type; // generic, boardingPass, coupon, eventTicket, storeCard
  final String organizationName;
  final String? description;
  final String? logoText;
  final String? backgroundColor;
  final String? foregroundColor;
  final String? labelColor;
  final String barcodeValue;
  final String? barcodeFormat;
  final String? barcodeAltText;
  final String? transitType;
  final String? relevantDate;
  final String? frontImagePath;
  final String? backImagePath;
  final String? stripImagePath;
  final String? thumbnailImagePath;
  final Map<String, dynamic>? fields; 
  int orderIndex;

  Pass({
    this.id,
    required this.type,
    required this.organizationName,
    this.description,
    this.logoText,
    this.backgroundColor,
    this.foregroundColor,
    this.labelColor,
    required this.barcodeValue,
    this.barcodeFormat,
    this.barcodeAltText,
    this.transitType,
    this.relevantDate,
    this.frontImagePath,
    this.backImagePath,
    this.stripImagePath,
    this.thumbnailImagePath,
    this.fields,
    this.orderIndex = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'organizationName': organizationName,
      'description': description,
      'logoText': logoText,
      'backgroundColor': backgroundColor,
      'foregroundColor': foregroundColor,
      'labelColor': labelColor,
      'barcodeValue': barcodeValue,
      'barcodeFormat': barcodeFormat,
      'barcodeAltText': barcodeAltText,
      'transitType': transitType,
      'relevantDate': relevantDate,
      'frontImagePath': frontImagePath,
      'backImagePath': backImagePath,
      'stripImagePath': stripImagePath,
      'thumbnailImagePath': thumbnailImagePath,
      'fields': fields != null ? jsonEncode(fields) : null,
      'orderIndex': orderIndex,
    };
  }

  Map<String, dynamic> toEncryptedMap() {
    final enc = EncryptionService.instance;
    return {
      'id': id,
      'type': type,
      'organizationName': enc.encryptText(organizationName),
      'description': enc.encryptText(description),
      'logoText': enc.encryptText(logoText),
      'backgroundColor': backgroundColor,
      'foregroundColor': foregroundColor,
      'labelColor': labelColor,
      'barcodeValue': enc.encryptText(barcodeValue),
      'barcodeFormat': barcodeFormat,
      'barcodeAltText': enc.encryptText(barcodeAltText),
      'transitType': transitType,
      'relevantDate': enc.encryptText(relevantDate),
      'frontImagePath': frontImagePath,
      'backImagePath': backImagePath,
      'stripImagePath': stripImagePath,
      'thumbnailImagePath': thumbnailImagePath,
      'fields': fields != null ? enc.encryptJson(fields!) : null,
      'orderIndex': orderIndex,
    };
  }

  factory Pass.fromMap(Map<String, dynamic> map) {
    return Pass(
      id: map['id'],
      type: map['type'],
      organizationName: map['organizationName'],
      description: map['description'],
      logoText: map['logoText'],
      backgroundColor: map['backgroundColor'],
      foregroundColor: map['foregroundColor'],
      labelColor: map['labelColor'],
      barcodeValue: map['barcodeValue'],
      barcodeFormat: map['barcodeFormat'],
      barcodeAltText: map['barcodeAltText'],
      transitType: map['transitType'],
      relevantDate: map['relevantDate'],
      frontImagePath: map['frontImagePath'],
      backImagePath: map['backImagePath'],
      stripImagePath: map['stripImagePath'],
      thumbnailImagePath: map['thumbnailImagePath'],
      fields: map['fields'] != null ? jsonDecode(map['fields']) : null,
      orderIndex: map['orderIndex'] ?? 0,
    );
  }

  factory Pass.fromEncryptedMap(Map<String, dynamic> map) {
    final enc = EncryptionService.instance;
    return Pass(
      id: map['id'],
      type: map['type'] ?? 'generic',
      organizationName: enc.decryptText(map['organizationName']) ?? '',
      description: enc.decryptText(map['description']),
      logoText: enc.decryptText(map['logoText']),
      backgroundColor: map['backgroundColor'],
      foregroundColor: map['foregroundColor'],
      labelColor: map['labelColor'],
      barcodeValue: enc.decryptText(map['barcodeValue']) ?? '',
      barcodeFormat: map['barcodeFormat'],
      barcodeAltText: enc.decryptText(map['barcodeAltText']),
      transitType: map['transitType'],
      relevantDate: enc.decryptText(map['relevantDate']),
      frontImagePath: map['frontImagePath'],
      backImagePath: map['backImagePath'],
      stripImagePath: map['stripImagePath'],
      thumbnailImagePath: map['thumbnailImagePath'],
      fields: map['fields'] != null ? enc.decryptJsonToDynamicMap(map['fields']) : null,
      orderIndex: map['orderIndex'] ?? 0,
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
      'spends': enc.encryptText(spends),
      'rewards': enc.encryptText(rewards),
      'annualFeeWaiver': enc.encryptText(annualFeeWaiver),
      'maxlimit': enc.encryptText(maxlimit),
      'cardtype': enc.encryptText(cardtype),
      'billdate': enc.encryptText(billdate),
      'category': enc.encryptText(category),
      'color': color,
      'frontImagePath': frontImagePath,
      'backImagePath': backImagePath,
      'orderIndex': orderIndex,
    };
  }

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
      spends: enc.decryptText(map['spends']),
      rewards: enc.decryptText(map['rewards']),
      annualFeeWaiver: enc.decryptText(map['annualFeeWaiver']),
      maxlimit: enc.decryptText(map['maxlimit']),
      cardtype: enc.decryptText(map['cardtype']),
      billdate: enc.decryptText(map['billdate']),
      category: enc.decryptText(map['category']),
      color: map['color'],
      frontImagePath: map['frontImagePath'],
      backImagePath: map['backImagePath'],
      orderIndex: map['orderIndex'] ?? 0,
    );
  }
}
