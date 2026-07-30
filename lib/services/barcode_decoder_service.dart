import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:zxing_lib/zxing.dart';
import 'package:zxing_lib/common.dart';

class BarcodeScanResult {
  final String text;
  final String? format;

  BarcodeScanResult({required this.text, this.format});
}

class BarcodeDecoderService {
  static Future<BarcodeScanResult?> scanImageFile(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) return null;

      final width = decodedImage.width;
      final height = decodedImage.height;

      final Int32List pixels = Int32List(width * height);
      int index = 0;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final pixel = decodedImage.getPixel(x, y);
          final r = pixel.r.toInt();
          final g = pixel.g.toInt();
          final b = pixel.b.toInt();
          final a = pixel.a.toInt();
          pixels[index++] = (a << 24) | (r << 16) | (g << 8) | b;
        }
      }

      final luminanceSource = RGBLuminanceSource(width, height, pixels);
      final bitmap = BinaryBitmap(HybridBinarizer(luminanceSource));

      final reader = MultiFormatReader();
      final hints = DecodeHint(tryHarder: true);

      try {
        final result = reader.decode(bitmap, hints);
        final formatString = _convertFormatName(result.barcodeFormat.name);
        return BarcodeScanResult(text: result.text, format: formatString);
      } catch (_) {
        // Fallback: Try inverted luminance source in case of light code on dark background
        try {
          final invertedBitmap = BinaryBitmap(HybridBinarizer(luminanceSource.invert()));
          final resultInverted = reader.decode(invertedBitmap, hints);
          final formatString = _convertFormatName(resultInverted.barcodeFormat.name);
          return BarcodeScanResult(text: resultInverted.text, format: formatString);
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  static String? _convertFormatName(String formatName) {
    switch (formatName.toUpperCase()) {
      case 'QR_CODE':
        return 'QR Code';
      case 'CODE_128':
        return 'Code 128';
      case 'CODE_39':
        return 'Code 39';
      case 'CODE_93':
        return 'Code 93';
      case 'EAN_13':
        return 'EAN-13';
      case 'EAN_8':
        return 'EAN-8';
      case 'UPC_A':
        return 'UPC-A';
      case 'UPC_E':
        return 'UPC-E';
      case 'PDF_417':
        return 'PDF417';
      case 'AZTEC':
        return 'Aztec';
      case 'DATA_MATRIX':
        return 'Data Matrix';
      case 'CODABAR':
        return 'Codabar';
      case 'ITF':
        return 'ITF';
      default:
        return null;
    }
  }
}
