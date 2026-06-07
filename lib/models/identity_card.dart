import 'package:wallet/services/encryption_service.dart';

class IdentityCard {
  final int? id;
  final String name;
  final String value;
  final String cardType; // e.g., Passport, License, etc.
  final String? frontImagePath;
  final String? backImagePath;
  int orderIndex;

  IdentityCard({
    this.id,
    required this.name,
    required this.value,
    this.cardType = 'Identity Card',
    this.frontImagePath,
    this.backImagePath,
    this.orderIndex = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'value': value,
      'cardType': cardType,
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
      'value': enc.encryptText(value),
      'cardType': enc.encryptText(cardType),
      'frontImagePath': frontImagePath,
      'backImagePath': backImagePath,
      'orderIndex': orderIndex,
    };
  }

  factory IdentityCard.fromMap(Map<String, dynamic> map) {
    return IdentityCard(
      id: map['id'],
      name: map['name'],
      value: map['value'],
      cardType: map['cardType'] ?? 'Identity Card',
      frontImagePath: map['frontImagePath'],
      backImagePath: map['backImagePath'],
      orderIndex: map['orderIndex'] ?? 0,
    );
  }

  factory IdentityCard.fromEncryptedMap(Map<String, dynamic> map) {
    final enc = EncryptionService.instance;
    return IdentityCard(
      id: map['id'],
      name: enc.decryptText(map['name']) ?? '',
      value: enc.decryptText(map['value']) ?? '',
      cardType: enc.decryptText(map['cardType']) ?? 'Identity Card',
      frontImagePath: map['frontImagePath'],
      backImagePath: map['backImagePath'],
      orderIndex: map['orderIndex'] ?? 0,
    );
  }
}
