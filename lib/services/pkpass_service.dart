import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:wallet/models/db_helper.dart';
import 'package:wallet/services/encryption_service.dart';

class PkpassService {
  static final PkpassService instance = PkpassService._();
  PkpassService._();

  Future<Loyalty?> parsePkpass(String filePath) async {
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
      String number = '';
      String? balance;
      Map<String, String> customFields = {};
      
      // Extract barcode message as the loyalty number
      if (passJson['barcode'] != null) {
        number = passJson['barcode']['message'] ?? '';
      } else if (passJson['barcodes'] != null && passJson['barcodes'] is List && (passJson['barcodes'] as List).isNotEmpty) {
        number = (passJson['barcodes'] as List)[0]['message'] ?? '';
      }

      // Look for balance and other fields
      final types = ['storeCard', 'coupon', 'eventTicket', 'generic', 'boardingPass'];
      for (var type in types) {
        if (passJson[type] != null) {
          final fields = <dynamic>[
            ...(passJson[type]['primaryFields'] ?? []),
            ...(passJson[type]['secondaryFields'] ?? []),
            ...(passJson[type]['auxiliaryFields'] ?? []),
            ...(passJson[type]['backFields'] ?? []),
          ];

          for (var field in fields) {
            final key = field['key']?.toString() ?? '';
            final label = field['label']?.toString() ?? key;
            final value = field['value']?.toString() ?? '';

            if (value.isNotEmpty) {
              if (key.toLowerCase().contains('balance') && balance == null) {
                balance = value;
              } else {
                customFields[label] = value;
              }
            }
          }
          
          if (number.isEmpty && fields.isNotEmpty) {
            number = fields[0]['value']?.toString() ?? '';
          }
        }
      }

      // Extract colors
      String? colorName = _mapColorToPalette(passJson['backgroundColor']);

      // Extract images (logo and icon)
      String? logoPath;
      String? iconPath;

      final logoFile = archive.findFile('logo.png') ?? archive.findFile('logo@2x.png') ?? archive.findFile('logo@3x.png');
      if (logoFile != null) {
        logoPath = await _saveAndEncryptArchiveFile(logoFile);
      }

      final iconFile = archive.findFile('icon.png') ?? archive.findFile('icon@2x.png') ?? archive.findFile('icon@3x.png');
      if (iconFile != null) {
        iconPath = await _saveAndEncryptArchiveFile(iconFile);
      }

      return Loyalty(
        loyaltyName: name,
        loyaltyNumber: number,
        balance: balance,
        customFields: customFields.isNotEmpty ? customFields : null,
        color: colorName ?? 'obsidian',
        frontImagePath: logoPath,
        backImagePath: iconPath,
      );
    } catch (e) {
      debugPrint('PkpassService: Error parsing .pkpass: $e');
      return null;
    }
  }

  /// Maps "rgb(r, g, b)" string to our app's color palette
  String? _mapColorToPalette(String? rgbString) {
    if (rgbString == null) return null;
    
    try {
      // Parse "rgb(255, 255, 255)" or "rgba(255, 255, 255, 1)"
      final match = RegExp(r'rgb\((\d+),\s*(\d+),\s*(\d+)\)').firstMatch(rgbString.toLowerCase());
      if (match != null) {
        final r = int.parse(match.group(1)!);
        final g = int.parse(match.group(2)!);
        final b = int.parse(match.group(3)!);
        
        // Find the "closest" color in our palette using simple Euclidean distance
        String closestKey = 'obsidian';
        double minDistance = double.infinity;

        // Pre-defined palette centers (rough approximations for mapping)
        const paletteCenters = {
          'obsidian': [15, 15, 15],
          'midnight': [15, 23, 42],
          'slate': [30, 41, 59],
          'indigo': [30, 27, 75],
          'violet': [46, 16, 101],
          'ocean': [12, 74, 110],
          'teal': [19, 78, 74],
          'emerald': [6, 78, 59],
          'amber': [120, 53, 15],
          'rose': [76, 5, 25],
        };

        paletteCenters.forEach((key, center) {
          final dist = _calculateDistance([r, g, b], center);
          if (dist < minDistance) {
            minDistance = dist;
            closestKey = key;
          }
        });

        return closestKey;
      }
    } catch (e) {
      debugPrint('PkpassService: Error mapping color: $e');
    }
    
    return 'obsidian';
  }

  double _calculateDistance(List<int> c1, List<int> c2) {
    return (c1[0] - c2[0]) * (c1[0] - c2[0]) +
           (c1[1] - c2[1]) * (c1[1] - c2[1]) +
           (c1[2] - c2[2]) * (c1[2] - c2[2]) + 0.0;
  }

  Future<String?> _saveAndEncryptArchiveFile(ArchiveFile file) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${const Uuid().v4()}.png';
      final filePath = p.join(directory.path, fileName);
      
      final outFile = File(filePath);
      await outFile.writeAsBytes(file.content);

      // Encrypt the file using the existing encryption service
      final encryptedPath = await EncryptionService.instance.encryptImageFile(filePath);
      
      // Delete unencrypted file
      if (await outFile.exists()) {
        await outFile.delete();
      }
      
      return encryptedPath;
    } catch (e) {
      debugPrint('PkpassService: Error saving image: $e');
      return null;
    }
  }
}
