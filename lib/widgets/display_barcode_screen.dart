// lib/widgets/display_barcode_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:screen_brightness/screen_brightness.dart';
import '../models/theme_provider.dart';

class DisplayBarcodeScreen extends StatefulWidget {
  final String barcodeData;
  final String cardName;

  const DisplayBarcodeScreen({
    super.key,
    required this.barcodeData,
    required this.cardName,
  });

  @override
  State<DisplayBarcodeScreen> createState() => _DisplayBarcodeScreenState();
}

class _DisplayBarcodeScreenState extends State<DisplayBarcodeScreen> {
  double _originalBrightness = 0.5;

  @override
  void initState() {
    super.initState();
    _setBrightnessToMax();
  }

  @override
  void dispose() {
    _resetBrightness();
    super.dispose();
  }

  Future<void> _setBrightnessToMax() async {
    try {
      _originalBrightness = await ScreenBrightness().current;
      await ScreenBrightness().setScreenBrightness(1.0);
    } catch (e) {
      debugPrint("Failed to set brightness: $e");
    }
  }

  Future<void> _resetBrightness() async {
    try {
      await ScreenBrightness().setScreenBrightness(_originalBrightness);
    } catch (e) {
      debugPrint("Failed to reset brightness: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final barcodeFormats = [
      {'format': Barcode.qrCode(), 'name': 'QR Code'},
      {'format': Barcode.code128(), 'name': 'Code 128'},
      {'format': Barcode.aztec(), 'name': 'Aztec'},
    ];

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.cardName,
                    style: themeProvider.getTextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: PageView.builder(
                      itemCount: barcodeFormats.length,
                      itemBuilder: (context, index) {
                        final item = barcodeFormats[index];
                        return _buildBarcodeWidget(
                          context,
                          item['format'] as Barcode,
                          widget.barcodeData,
                          item['name'] as String,
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "Swipe for different formats",
                      style: themeProvider.getTextStyle(
                        fontSize: 12,
                        color: themeProvider.getTextStyle().color?.withAlpha(
                          128,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withAlpha(26),
                  foregroundColor: themeProvider.getTextStyle().color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarcodeWidget(
    BuildContext context,
    Barcode barcode,
    String data,
    String title,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // ** FIXED: Increased size to 95% of screen width **
        final isQr =
            barcode.name.contains('qr') || barcode.name.contains('aztec');
        final double containerWidth =
            constraints.maxWidth * 0.95; // Use 95% of width

        // Internal barcode widget should also fill the container more
        final double barcodeSize = isQr
            ? containerWidth - 40
            : containerWidth - 40; // Adjust for padding

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20), // Reduced padding slightly
              width: containerWidth, // Apply the new width
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(26),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: BarcodeWidget(
                barcode: barcode,
                data: data,
                width: barcodeSize,
                height: isQr
                    ? barcodeSize
                    : barcodeSize / 2, // Keep aspect ratio
                color: Colors.black,
                errorBuilder: (context, error) => const Center(
                  child: Text(
                    'Invalid Data for this Barcode Type',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(title),
          ],
        );
      },
    );
  }
}
