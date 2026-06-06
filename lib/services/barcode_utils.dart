import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';

class BarcodeUtils {
  static Map<String, Barcode> get supportedFormats => {
        'QR Code': Barcode.qrCode(),
        'Code 128': Barcode.code128(),
        'Code 39': Barcode.code39(),
        'Code 93': Barcode.code93(),
        'EAN-13': Barcode.ean13(),
        'EAN-8': Barcode.ean8(),
        'UPC-A': Barcode.upcA(),
        'UPC-E': Barcode.upcE(),
        'PDF417': Barcode.pdf417(),
        'Aztec': Barcode.aztec(),
        'Data Matrix': Barcode.dataMatrix(),
        'Codabar': Barcode.codabar(),
        'ITF': Barcode.itf(),
        'ITF-14': Barcode.itf14(),
        'GS1-128': Barcode.gs128(),
        'ISBN': Barcode.isbn(),
        'Telepen': Barcode.telepen(),
        'POSTNET': Barcode.postnet(),
        'RM4SCC': Barcode.rm4scc(),
        'EAN-2': Barcode.ean2(),
        'EAN-5': Barcode.ean5(),
      };

  static IconData getIconForFormat(String format) {
    switch (format) {
      case 'QR Code':
        return Icons.qr_code_2_rounded;
      case 'Aztec':
        return Icons.blur_circular_rounded;
      case 'Data Matrix':
        return Icons.grid_4x4_rounded;
      case 'PDF417':
        return Icons.picture_as_pdf_rounded;
      default:
        return Icons.view_week_rounded;
    }
  }

  static String getInternalFormatName(String label) {
    switch (label) {
      case 'QR Code': return 'PKBarcodeFormatQR';
      case 'PDF417': return 'PKBarcodeFormatPDF417';
      case 'Aztec': return 'PKBarcodeFormatAztec';
      case 'Code 128': return 'PKBarcodeFormatCode128';
      default: return label;
    }
  }

  static String getLabelFromFormat(String? format) {
    if (format == null) return 'QR Code';
    switch (format) {
      case 'PKBarcodeFormatQR': return 'QR Code';
      case 'PKBarcodeFormatPDF417': return 'PDF417';
      case 'PKBarcodeFormatAztec': return 'Aztec';
      case 'PKBarcodeFormatCode128': return 'Code 128';
      default: return format;
    }
  }

  static Barcode getBarcodeFromFormat(String? format) {
    final label = getLabelFromFormat(format);
    return supportedFormats[label] ?? Barcode.qrCode();
  }
}
