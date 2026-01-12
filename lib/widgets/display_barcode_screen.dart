// lib/widgets/display_barcode_screen.dart - MODERN 2024 DESIGN

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late final List<_BarcodeFormat> _formats;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _formats = [
      _BarcodeFormat(Barcode.code128(), 'Barcode', Icons.view_week_rounded),
      _BarcodeFormat(Barcode.qrCode(), 'QR Code', Icons.qr_code_2_rounded),
      _BarcodeFormat(Barcode.aztec(), 'Aztec', Icons.blur_circular_rounded),
      _BarcodeFormat(Barcode.dataMatrix(), 'Matrix', Icons.grid_4x4_rounded),
    ];

    // Set to max brightness for easy scanning
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final bgColor = isDark ? const Color(0xFF0A0A0A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, isDark, textColor),

            // Barcode Display
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildBarcodeCard(isDark),
                ),
              ),
            ),

            // Format Selector
            _buildFormatSelector(isDark, textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Close button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withAlpha(15)
                    : Colors.black.withAlpha(8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.close_rounded, color: textColor, size: 22),
            ),
          ),
          const SizedBox(width: 16),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.cardName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Show this to cashier",
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          // Copy button
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.barcodeData));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  content: const Text('Copied to clipboard'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withAlpha(15)
                    : Colors.black.withAlpha(8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.copy_rounded, color: textColor, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarcodeCard(bool isDark) {
    final format = _formats[_selectedIndex];
    final isSquare = _selectedIndex > 0; // QR, Aztec, Matrix are square

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barcode
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            constraints: BoxConstraints(
              maxWidth: isSquare ? 200 : double.infinity,
              minHeight: isSquare ? 200 : 80,
            ),
            child: BarcodeWidget(
              barcode: format.barcode,
              data: widget.barcodeData,
              color: Colors.black,
              height: isSquare ? 200 : 80,
              errorBuilder: (context, error) => _buildError(),
            ),
          ),

          const SizedBox(height: 28),

          // Separator
          Container(height: 1, color: Colors.grey.shade200),

          const SizedBox(height: 20),

          // Number
          SelectableText(
            widget.barcodeData,
            style: const TextStyle(
              fontFamily: 'ZSpace',
              fontSize: 18,
              letterSpacing: 2,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      height: 100,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'Cannot display in this format',
            style: TextStyle(color: Colors.red.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatSelector(bool isDark, Color textColor) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(_formats.length, (index) {
          final format = _formats[index];
          final isSelected = index == _selectedIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? Colors.white : Colors.black)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      format.icon,
                      size: 22,
                      color: isSelected
                          ? (isDark ? Colors.black : Colors.white)
                          : (isDark ? Colors.white54 : Colors.black45),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      format.name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? (isDark ? Colors.black : Colors.white)
                            : (isDark ? Colors.white54 : Colors.black45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _BarcodeFormat {
  final Barcode barcode;
  final String name;
  final IconData icon;

  _BarcodeFormat(this.barcode, this.name, this.icon);
}
