import 'dart:convert';
import 'package:wallet/services/encryption_service.dart';

class Pass {
  final int? id;
  final String type;
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
