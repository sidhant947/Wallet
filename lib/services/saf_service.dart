import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SafService {
  static const _channel = MethodChannel('com.sidhant.wallet/save_file');

  static Future<String?> pickDirectory() async {
    try {
      final result = await _channel.invokeMethod<String>('pickDirectory');
      return result;
    } catch (e) {
      debugPrint('SafService.pickDirectory failed: $e');
      return null;
    }
  }

  static Future<bool> writeToUri(String uri, String filename, List<int> bytes) async {
    try {
      await _channel.invokeMethod('writeToUri', {
        'uri': uri,
        'filename': filename,
        'bytes': Uint8List.fromList(bytes),
      });
      return true;
    } catch (e) {
      debugPrint('SafService.writeToUri failed: $e');
      return false;
    }
  }

  static Future<Uint8List?> readFromUri(String uri, String filename) async {
    try {
      final result = await _channel.invokeMethod<Uint8List>('readFromUri', {
        'uri': uri,
        'filename': filename,
      });
      return result;
    } catch (e) {
      debugPrint('SafService.readFromUri failed: $e');
      return null;
    }
  }

  static Future<bool> deleteFromUri(String uri, String filename) async {
    try {
      await _channel.invokeMethod('deleteFromUri', {
        'uri': uri,
        'filename': filename,
      });
      return true;
    } catch (e) {
      debugPrint('SafService.deleteFromUri failed: $e');
      return false;
    }
  }
}
