import 'dart:io';
import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:provider/provider.dart';
import 'package:wallet/models/db_helper.dart';
import 'package:wallet/models/theme_provider.dart';
import 'package:wallet/pages/walletdetails.dart';

class BarcodeCardDetailScreen extends StatelessWidget {
  final Loyalty? loyalty;
  final Identity? identity;

  const BarcodeCardDetailScreen({super.key, this.loyalty, this.identity})
    : assert(loyalty != null || identity != null);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    // Determine which card type is being displayed
    final bool isLoyaltyCard = loyalty != null;

    final cardName = isLoyaltyCard
        ? loyalty!.loyaltyName
        : identity!.identityName;
    final barcodeData = isLoyaltyCard
        ? loyalty!.loyaltyNumber
        : identity!.identityNumber;
    final frontImagePath = isLoyaltyCard
        ? loyalty!.frontImagePath
        : identity!.frontImagePath;
    final backImagePath = isLoyaltyCard
        ? loyalty!.backImagePath
        : identity!.backImagePath;

    bool isPathValid(String? path) => path != null && path.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(cardName),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : Colors.black,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Barcode Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: BarcodeWidget(
              barcode: Barcode.code128(),
              data: barcodeData,
              color: Colors.black,
              height: 100,
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
          // Barcode number display
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
            ),
            child: Center(
              child: Text(
                barcodeData,
                style: TextStyle(
                  fontFamily: 'ZSpace',
                  fontSize: 20,
                  letterSpacing: 2,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Images Section
          if (isPathValid(frontImagePath) || isPathValid(backImagePath))
            _LiquidGlassSection(
              title: "Card Images",
              icon: Icons.photo_library_outlined,
              isDark: isDark,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (isPathValid(frontImagePath))
                    _buildImageThumbnail(
                      context,
                      frontImagePath!,
                      'Front',
                      isDark,
                    ),
                  if (isPathValid(backImagePath))
                    _buildImageThumbnail(
                      context,
                      backImagePath!,
                      'Back',
                      isDark,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(
    BuildContext context,
    String imagePath,
    String label,
    bool isDark,
  ) {
    final imageFile = File(imagePath);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    FullScreenImageViewer(imageFile: imageFile),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  imageFile,
                  height: 100,
                  width: 150,
                  fit: BoxFit.cover,
                  cacheHeight: 200,
                  cacheWidth: 300,
                  errorBuilder: (c, e, s) => Container(
                    height: 100,
                    width: 150,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1A1A1A)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.error_outline,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiquidGlassSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool isDark;

  const _LiquidGlassSection({
    required this.title,
    required this.icon,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
          ),
          child: child,
        ),
      ],
    );
  }
}
