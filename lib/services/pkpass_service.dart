import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:wallet/models/db_helper.dart';

class PkpassService {
  static final PkpassService instance = PkpassService._();
  PkpassService._();

  Future<Pass?> parsePkpass(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Find pass.json
      final passFile = archive.findFile('pass.json');
      if (passFile == null) {
        debugPrint('PkpassService: pass.json not found in archive');
        return null;
      }

      final passJson = jsonDecode(utf8.decode(passFile.content));
      
      // Extract basic info
      String name = passJson['organizationName'] ?? passJson['description'] ?? 'Imported Pass';
      String description = passJson['description'] ?? '';
      String? logoText = passJson['logoText'];
      String number = '';
      String? barcodeFormat;
      String? barcodeAltText;
      
      // Extract barcode info
      if (passJson['barcode'] != null) {
        number = passJson['barcode']['message'] ?? '';
        barcodeFormat = passJson['barcode']['format']?.toString();
        barcodeAltText = passJson['barcode']['altText']?.toString();
      } else if (passJson['barcodes'] != null && passJson['barcodes'] is List && (passJson['barcodes'] as List).isNotEmpty) {
        number = (passJson['barcodes'] as List)[0]['message'] ?? '';
        barcodeFormat = (passJson['barcodes'] as List)[0]['format']?.toString();
        barcodeAltText = (passJson['barcodes'] as List)[0]['altText']?.toString();
      }

      // Determine pass type and extract fields
      final types = ['storeCard', 'coupon', 'eventTicket', 'generic', 'boardingPass'];
      String passType = 'generic';
      Map<String, dynamic> fields = {};
      String? transitType;

      for (var type in types) {
        if (passJson[type] != null) {
          passType = type;
          final passData = passJson[type];
          
          fields['primaryFields'] = passData['primaryFields'];
          fields['secondaryFields'] = passData['secondaryFields'];
          fields['auxiliaryFields'] = passData['auxiliaryFields'];
          fields['backFields'] = passData['backFields'];
          fields['headerFields'] = passData['headerFields'];

          if (type == 'boardingPass') {
            transitType = passData['transitType'];
          }
          break;
        }
      }

      // Extract colors
      String? backgroundColor = passJson['backgroundColor'];
      String? foregroundColor = passJson['foregroundColor'];
      String? labelColor = passJson['labelColor'];

      // Images extraction disabled as per instructions

      return Pass(
        type: passType,
        organizationName: name,
        description: description,
        logoText: logoText,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        labelColor: labelColor,
        barcodeValue: number,
        barcodeFormat: barcodeFormat,
        barcodeAltText: barcodeAltText,
        transitType: transitType,
        relevantDate: passJson['relevantDate']?.toString(),
        frontImagePath: null,
        backImagePath: null,
        stripImagePath: null,
        thumbnailImagePath: null,
        fields: fields,
      );
    } catch (e) {
      debugPrint('PkpassService: Error parsing .pkpass: $e');
      return null;
    }
  }
}
