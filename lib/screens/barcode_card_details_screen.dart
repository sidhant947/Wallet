import 'dart:io';
import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:wallet/models/db_helper.dart';
import 'package:wallet/pages/walletdetails.dart'; // Reusing FullScreenImageViewer

class BarcodeCardDetailScreen extends StatelessWidget {
  final Loyalty? loyalty;
  final Identity? identity;

  const BarcodeCardDetailScreen({super.key, this.loyalty, this.identity})
    : assert(loyalty != null || identity != null);

  @override
  Widget build(BuildContext context) {
    // --- FIXED: Safely get all card properties ---

    // 1. First, determine which card type is being displayed.
    final bool isLoyaltyCard = loyalty != null;

    // 2. Then, get all data from the correct, non-null object.
    // The '!' is now safe because we've confirmed which object is not null.
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

    // --- End of fix ---

    // Utility to check if a path is valid for display
    bool isPathValid(String? path) => path != null && path.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(cardName)),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Barcode Section
          Container(
            padding: const EdgeInsets.all(20),
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
              barcode: Barcode.code128(),
              data: barcodeData,
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
          const SizedBox(height: 8),
          Center(
            child: Text(
              barcodeData,
              style: const TextStyle(
                fontFamily: 'ZSpace',
                fontSize: 18,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Images Section
          if (isPathValid(frontImagePath) || isPathValid(backImagePath))
            Column(
              children: [
                if (isPathValid(frontImagePath))
                  _buildImageThumbnail(context, frontImagePath!, 'Front'),
                if (isPathValid(backImagePath))
                  _buildImageThumbnail(context, backImagePath!, 'Back'),
                const SizedBox(height: 16),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(
    BuildContext context,
    String imagePath,
    String label,
  ) {
    final imageFile = File(imagePath);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                imageFile,
                height: 100,
                width: 150,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  height: 100,
                  width: 150,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.error_outline),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }
}
