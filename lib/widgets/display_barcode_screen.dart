// lib/widgets/display_barcode_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart';
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
  late final List<Map<String, dynamic>> _barcodeFormats;
  late Barcode _selectedFormat;
  late String _selectedFormatName;

  @override
  void initState() {
    super.initState();

    _barcodeFormats = [
      {'format': Barcode.code128(), 'name': 'Code 128'},
      {'format': Barcode.qrCode(), 'name': 'QR Code'},
      {'format': Barcode.aztec(), 'name': 'Aztec'},
      {'format': Barcode.dataMatrix(), 'name': 'Data Matrix'},
    ];

    _selectedFormat = _barcodeFormats.first['format'] as Barcode;
    _selectedFormatName = _barcodeFormats.first['name'] as String;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Card name with glass container
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.03),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                      ),
                    ),
                    child: Text(
                      widget.cardName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Barcode display with liquid glass effect
                  _buildBarcodeWidget(
                    context,
                    _selectedFormat,
                    widget.barcodeData,
                    isDark,
                  ),

                  const SizedBox(height: 40),

                  // Format selector with glass effect
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.03),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.05),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: SegmentedButton<String>(
                            segments: _barcodeFormats.map((item) {
                              return ButtonSegment<String>(
                                value: item['name'] as String,
                                label: Text(
                                  item['name'] as String,
                                  style: const TextStyle(fontSize: 12),
                                ),
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
                                _selectedFormat =
                                    selectedItem['format'] as Barcode;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),
                ],
              ),
            ),
            // Close button with glass effect
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                ),
                child: IconButton(
                  icon: Icon(Icons.close_rounded, color: textColor),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
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
    bool isDark,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isQr =
            barcode.name.contains('qr') ||
            barcode.name.contains('aztec') ||
            barcode.name.contains('matrix');
        final double containerWidth = constraints.maxWidth * 0.9;
        final double barcodeSize = containerWidth - 48;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: containerWidth,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.12),
                    blurRadius: 40,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                      ),
                    ),
                    child: BarcodeWidget(
                      barcode: barcode,
                      data: data,
                      width: barcodeSize,
                      height: isQr ? barcodeSize : barcodeSize / 2.5,
                      color: Colors.black,
                      errorBuilder: (context, error) => Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 48,
                                color: Colors.red.shade400,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Invalid Data for this Barcode Type',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
