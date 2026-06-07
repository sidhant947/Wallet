import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:wallet/services/encryption_service.dart';

/// Saves an image to the app's documents directory and encrypts it.
///
/// The image is first copied to the app directory, then encrypted using
/// AES-256-GCM. The original unencrypted file is deleted after encryption.
/// Returns the path to the encrypted file (.enc extension).
Future<String?> saveImageToAppDirectory(File imageFile) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final fileExtension = p.extension(imageFile.path);
    final newFileName =
        '${DateTime.now().microsecondsSinceEpoch}$fileExtension';
    final newPath = p.join(directory.path, newFileName);
    final newFile = await imageFile.copy(newPath);

    // Encrypt the saved image file
    final encryptedPath = await EncryptionService.instance.encryptImageFile(
      newFile.path,
    );

    // Securely delete the original source file (e.g. from camera cache or gallery)
    // to ensure no plaintext traces are left on disk.
    if (await imageFile.exists()) {
      await imageFile.delete();
      debugPrint("EncryptionService: Original source image deleted.");
    }

    return encryptedPath;
  } catch (e) {
    debugPrint("Error saving/encrypting image: $e");
    return null;
  }
}
