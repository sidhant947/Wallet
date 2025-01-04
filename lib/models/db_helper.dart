import 'dart:async';
import 'package:flutter/material.dart';
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
      version: 2, // Incremented version for the database schema update
      onCreate: (db, version) {
        return db.execute(
          '''
          CREATE TABLE wallets(
            id INTEGER PRIMARY KEY,
            name TEXT,
            number TEXT,
            expiry TEXT,
            network TEXT,
            spends TEXT,
            rewards TEXT,
            annualFeeWaiver TEXT,
            maxlimit TEXT,
            cardtype TEXT,
            billdate TEXT,
            category TEXT
          )
          ''',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Adding new columns if the version is old (version 1)
          await db.execute('''
            ALTER TABLE wallets ADD COLUMN spends TEXT;
          ''');
          await db.execute('''
            ALTER TABLE wallets ADD COLUMN rewards TEXT;
          ''');
          await db.execute('''
            ALTER TABLE wallets ADD COLUMN annualFeeWaiver TEXT;
          ''');
          await db.execute('''
            ALTER TABLE wallets ADD COLUMN maxlimit TEXT;
          ''');
          await db.execute('''
            ALTER TABLE wallets ADD COLUMN cardtype TEXT;
          ''');
          await db.execute('''
            ALTER TABLE wallets ADD COLUMN billdate TEXT;
          ''');
          await db.execute('''
            ALTER TABLE wallets ADD COLUMN category TEXT;
          ''');
          await db.execute('''
            ALTER TABLE wallets ADD COLUMN network TEXT;
          ''');
        }
      },
    );
  }

  Future<int> insertWallet(Wallet wallet) async {
    Database db = await instance.database;
    return await db.insert('wallets', wallet.toMap());
  }

  Future<List<Wallet>> getWallets() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('wallets');
    return List.generate(maps.length, (i) {
      return Wallet.fromMap(maps[i]);
    });
  }

  Future<int> deleteWallet(int id) async {
    Database db = await instance.database;
    return await db.delete(
      'wallets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateWallet(Wallet wallet) async {
    Database db = await instance.database;
    return await db.update(
      'wallets',
      wallet.toMap(),
      where: 'id = ?',
      whereArgs: [wallet.id],
    );
  }
}

class Wallet {
  final int? id;
  late final String name;
  late final String number;
  late final String expiry;
  final String? network;
  final String? spends; // Optional field
  final String? rewards; // Optional field
  final String? annualFeeWaiver; // Optional field
  final String? maxlimit; // Optional field
  late final String? cardtype; // Optional field
  final String? billdate; // Optional field
  final String? category; // Optional field

  Wallet({
    this.id,
    required this.name,
    required this.number,
    required this.expiry,
    this.network,
    this.spends,
    this.rewards,
    this.annualFeeWaiver,
    this.maxlimit,
    this.cardtype,
    this.billdate,
    this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'number': number,
      'expiry': expiry,
      'network': network,
      'spends': spends,
      'rewards': rewards,
      'annualFeeWaiver': annualFeeWaiver,
      'maxlimit': maxlimit,
      'cardtype': cardtype,
      'billdate': billdate,
      'category': category,
    };
  }

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'],
      name: map['name'],
      number: map['number'],
      expiry: map['expiry'],
      network: map['network'],
      spends: map['spends'],
      rewards: map['rewards'],
      annualFeeWaiver: map['annualFeeWaiver'],
      maxlimit: map['maxlimit'],
      cardtype: map['cardtype'],
      billdate: map['billdate'],
      category: map['category'],
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
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE identities(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        identityName TEXT,
        identityNumber TEXT
      )
    ''');
  }

  Future<int> insertIdentity(Identity identity) async {
    final db = await database;
    return await db.insert('identities', identity.toMap());
  }

  Future<List<Identity>> getAllIdentities() async {
    final db = await database;
    final result = await db.query('identities');
    return result.map((e) => Identity.fromMap(e)).toList();
  }

  Future<void> deleteIdentity(int id) async {
    final db = await database;
    await db.delete('identities', where: 'id = ?', whereArgs: [id]);
  }
}

class Identity {
  final int? id;
  final String identityName;
  final String identityNumber;

  Identity({this.id, required this.identityName, required this.identityNumber});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'identityName': identityName,
      'identityNumber': identityNumber,
    };
  }

  factory Identity.fromMap(Map<String, dynamic> map) {
    return Identity(
      id: map['id'],
      identityName: map['identityName'],
      identityNumber: map['identityNumber'],
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
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE loyalties(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        loyaltyName TEXT,
        loyaltyNumber TEXT
      )
    ''');
  }

  Future<int> insertLoyalty(Loyalty loyalty) async {
    final db = await database;
    return await db.insert('loyalties', loyalty.toMap());
  }

  Future<List<Loyalty>> getAllLoyalties() async {
    final db = await database;
    final result = await db.query('loyalties');
    return result.map((e) => Loyalty.fromMap(e)).toList();
  }

  Future<void> deleteLoyalty(int id) async {
    final db = await database;
    await db.delete('loyalties', where: 'id = ?', whereArgs: [id]);
  }
}

class Loyalty {
  final int? id;
  final String loyaltyName;
  final String loyaltyNumber;

  Loyalty({this.id, required this.loyaltyName, required this.loyaltyNumber});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'loyaltyName': loyaltyName,
      'loyaltyNumber': loyaltyNumber,
    };
  }

  factory Loyalty.fromMap(Map<String, dynamic> map) {
    return Loyalty(
      id: map['id'],
      loyaltyName: map['loyaltyName'],
      loyaltyNumber: map['loyaltyNumber'],
    );
  }
}
