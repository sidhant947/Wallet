// lib/widgets/display_barcode_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart';
// import 'package:screen_brightness/screen_brightness.dart';
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
  // final double _originalBrightness = 0.5;

  // --- MODIFIED: List of formats and the default selected format ---
  late final List<Map<String, dynamic>> _barcodeFormats;
  late Barcode _selectedFormat;
  late String _selectedFormatName;
  // --- END MODIFICATION ---

  @override
  void initState() {
    super.initState();
    // _setBrightnessToMax();

    // --- ADDED: Initialize the formats and set the default ---
    _barcodeFormats = [
      // Defaulting to Code 128 as it's common for cards
      {'format': Barcode.code128(), 'name': 'Code 128'},
      {'format': Barcode.qrCode(), 'name': 'QR Code'},
      {'format': Barcode.aztec(), 'name': 'Aztec'},
      {'format': Barcode.dataMatrix(), 'name': 'Data Matrix'},
    ];

    // Set the initial selection
    _selectedFormat = _barcodeFormats.first['format'] as Barcode;
    _selectedFormatName = _barcodeFormats.first['name'] as String;
    // --- END ADDITION ---
  }

  @override
  void dispose() {
    // _resetBrightness();
    super.dispose();
  }

  // ... (Brightness functions remain commented) ...

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

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
                    textAlign: TextAlign.center,
                    style: themeProvider.getTextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- MODIFIED: Removed PageView, now directly shows selected ---
                  _buildBarcodeWidget(
                    context,
                    _selectedFormat,
                    widget.barcodeData,
                    _selectedFormatName, // This title isn't used in the widget, but passing it
                  ),

                  // --- END MODIFICATION ---
                  const SizedBox(height: 32),

                  // --- ADDED: SegmentedButton for user to choose format ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SegmentedButton<String>(
                      segments: _barcodeFormats.map((item) {
                        return ButtonSegment<String>(
                          value: item['name'] as String,
                          label: Text(item['name'] as String),
                        );
                      }).toList(),
                      selected: <String>{_selectedFormatName},
                      onSelectionChanged: (Set<String> newSelection) {
                        final selectedName = newSelection.first;
                        final selectedItem = _barcodeFormats.firstWhere(
                          (item) => item['name'] == selectedName,
                        );

                        setState(() {
                          _selectedFormatName = selectedName;
                          _selectedFormat = selectedItem['format'] as Barcode;
                        });
                      },
                      style: SegmentedButton.styleFrom(
                        backgroundColor: Theme.of(context).cardColor,
                        side: BorderSide(color: Colors.grey.withAlpha(51)),
                      ),
                    ),
                  ),

                  // --- END ADDITION ---
                  const Spacer(), // Pushes content to center
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
    String title, // Title is no longer displayed inside this widget
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // ** FIXED: Increased size to 95% of screen width **
        final isQr =
            barcode.name.contains('qr') ||
            barcode.name.contains('aztec') ||
            barcode.name.contains('matrix');
        final double containerWidth =
            constraints.maxWidth * 0.9; // Use 90% of width

        final double barcodeSize = containerWidth - 40; // Adjust for padding

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
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
                    : barcodeSize / 2.5, // Made non-QR barcodes a bit shorter
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
            // --- MODIFIED: Removed the Text(title) from here ---
            // The title is now the SegmentedButton
          ],
        );
      },
    );
  }
}
