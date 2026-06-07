import 'dart:convert';
import 'package:wallet/services/encryption_service.dart';

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
