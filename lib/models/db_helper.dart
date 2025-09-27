import 'dart:async';
import 'dart:convert';
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
      version: 5, // MODIFIED: Incremented version
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
            backImagePath TEXT
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
    return List.generate(maps.length, (i) => Wallet.fromMap(maps[i]));
  }

  Future<int> deleteWallet(int id) async {
    Database db = await instance.database;
    return await db.delete('wallets', where: 'id = ?', whereArgs: [id]);
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
    this.frontImagePath, // MODIFIED
    this.backImagePath, // MODIFIED
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
      'frontImagePath': frontImagePath, // MODIFIED
      'backImagePath': backImagePath, // MODIFIED
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
      frontImagePath: map['frontImagePath'], // MODIFIED
      backImagePath: map['backImagePath'], // MODIFIED
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
      version: 3,
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
        backImagePath TEXT
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
      await db.execute('ALTER TABLE identities ADD COLUMN backImagePath TEXT;');
    }
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
  final String? color;
  final String? frontImagePath;
  final String? backImagePath;

  Identity({
    this.id,
    required this.identityName,
    required this.identityNumber,
    this.color,
    this.frontImagePath,
    this.backImagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'identityName': identityName,
      'identityNumber': identityNumber,
      'color': color,
      'frontImagePath': frontImagePath,
      'backImagePath': backImagePath,
    };
  }

  factory Identity.fromMap(Map<String, dynamic> map) {
    return Identity(
      id: map['id'],
      identityName: map['identityName'],
      identityNumber: map['identityNumber'],
      color: map['color'],
      frontImagePath: map['frontImagePath'],
      backImagePath: map['backImagePath'],
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
      version: 3,
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
        backImagePath TEXT
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
  final String? color;
  final String? frontImagePath;
  final String? backImagePath;

  Loyalty({
    this.id,
    required this.loyaltyName,
    required this.loyaltyNumber,
    this.color,
    this.frontImagePath,
    this.backImagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'loyaltyName': loyaltyName,
      'loyaltyNumber': loyaltyNumber,
      'color': color,
      'frontImagePath': frontImagePath,
      'backImagePath': backImagePath,
    };
  }

  factory Loyalty.fromMap(Map<String, dynamic> map) {
    return Loyalty(
      id: map['id'],
      loyaltyName: map['loyaltyName'],
      loyaltyNumber: map['loyaltyNumber'],
      color: map['color'],
      frontImagePath: map['frontImagePath'],
      backImagePath: map['backImagePath'],
    );
  }
}
