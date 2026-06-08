import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
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
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> generatePkpass(Pass pass) async {
    try {
      final passJson = _generatePassJson(pass);
      final passJsonContent = utf8.encode(jsonEncode(passJson));
      
      // A minimal 1x1 black PNG for icon.png (required by Apple Wallet)
      final iconBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x00, 0x00, 0x00, 0x00, 0x3A, 0x7E, 0x9B, 0x55, 0x00, 0x00, 0x00,
        0x0A, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0x60, 0x00, 0x00, 0x00,
        0x02, 0x00, 0x01, 0xE2, 0x21, 0xBC, 0x33, 0x00, 0x00, 0x00, 0x00, 0x49,
        0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
      ]);

      final manifest = {
        'pass.json': sha1.convert(passJsonContent).toString(),
        'icon.png': sha1.convert(iconBytes).toString(),
      };
      
      final archive = Archive();
      archive.addFile(ArchiveFile('pass.json', passJsonContent.length, passJsonContent));
      archive.addFile(ArchiveFile('icon.png', iconBytes.length, iconBytes));
      
      final manifestContent = utf8.encode(jsonEncode(manifest));
      archive.addFile(ArchiveFile('manifest.json', manifestContent.length, manifestContent));
      
      final zipData = ZipEncoder().encode(archive);
      return Uint8List.fromList(zipData);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _generatePassJson(Pass pass) {
    final Map<String, dynamic> passJson = {
      'formatVersion': 1,
      'passTypeIdentifier': 'pass.com.sidhant.wallet',
      'teamIdentifier': 'WALLETBOX',
      'serialNumber': pass.id?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'organizationName': pass.organizationName,
      'description': pass.description ?? pass.organizationName,
      'logoText': pass.logoText ?? pass.organizationName,
      'sharingProhibited': false,
    };

    if (pass.backgroundColor != null) passJson['backgroundColor'] = _hexToRgb(pass.backgroundColor!);
    if (pass.foregroundColor != null) passJson['foregroundColor'] = _hexToRgb(pass.foregroundColor!);
    if (pass.labelColor != null) passJson['labelColor'] = _hexToRgb(pass.labelColor!);

    if (pass.barcodeValue.isNotEmpty) {
      passJson['barcodes'] = [{
        'format': pass.barcodeFormat ?? 'PKBarcodeFormatQR',
        'message': pass.barcodeValue,
        'messageEncoding': 'iso-8859-1',
        'altText': pass.barcodeAltText ?? pass.barcodeValue,
      }];
      passJson['barcode'] = passJson['barcodes'][0];
    }

    final typeData = <String, dynamic>{};
    if (pass.fields != null) {
      pass.fields!.forEach((key, value) {
        if (value is List) {
          typeData[key] = value.map((f) => {
            'key': f['key'] ?? '${f['label']?.toString().toLowerCase().replaceAll(' ', '_') ?? 'field'}_${value.indexOf(f)}',
            'label': f['label'] ?? '',
            'value': f['value'] ?? '',
          }).toList();
        }
      });
    }

    if (pass.type == 'boardingPass' && pass.transitType != null) {
      typeData['transitType'] = pass.transitType;
    }

    passJson[pass.type] = typeData;

    return passJson;
  }

  String _hexToRgb(String hex) {
    if (!hex.startsWith('#')) return hex; // Already in rgb or other format
    hex = hex.replaceAll('#', '');
    try {
      if (hex.length == 6) {
        final r = int.parse(hex.substring(0, 2), radix: 16);
        final g = int.parse(hex.substring(2, 4), radix: 16);
        final b = int.parse(hex.substring(4, 6), radix: 16);
        return 'rgb($r, $g, $b)';
      }
    } catch (_) {}
    return 'rgb(0, 0, 0)';
  }
}
