// lib/widgets/barcode_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/theme_provider.dart';
import '../models/dataentry.dart';

class BarcodeCard extends StatelessWidget {
  final String cardName;
  final String cardNumber;
  final BarcodeCardType cardType;
  final VoidCallback onCardTap;
  final VoidCallback onBarcodeIconTap;

  const BarcodeCard({
    super.key,
    required this.cardName,
    required this.cardNumber,
    required this.cardType,
    required this.onCardTap,
    required this.onBarcodeIconTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isIdentity = cardType == BarcodeCardType.identity;
    final tapHint = isIdentity
        ? "Tap for barcode, Long press to copy"
        : "Tap for barcode, Long press to copy";

    return InkWell(
      onTap: onCardTap,
      onLongPress: () => onBarcodeIconTap(), // Use long press for copy now
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: themeProvider.isDarkMode
              ? null
              : [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    cardName,
                    style: themeProvider.getTextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  isIdentity
                      ? Icons.fingerprint
                      : Icons.shopping_basket_outlined,
                  size: 30,
                  color: themeProvider.getTextStyle().color?.withOpacity(0.6),
                ),
              ],
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                cardNumber,
                style: themeProvider
                    .getTextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: themeProvider.getTextStyle().color?.withOpacity(
                        0.8,
                      ),
                    )
                    .copyWith(fontFamily: 'ZSpace'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tapHint,
              style: themeProvider.getTextStyle(
                fontSize: 12,
                color: themeProvider.getTextStyle().color?.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
