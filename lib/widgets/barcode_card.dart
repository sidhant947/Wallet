import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallet/models/db_helper.dart';
import '../models/theme_provider.dart';
import '../models/dataentry.dart';

class BarcodeCard extends StatelessWidget {
  // MODIFIED: Pass full objects to get all data like color
  final Loyalty? loyalty;
  final Identity? identity;
  final BarcodeCardType cardType;
  final VoidCallback onCardTap;
  final VoidCallback onCopyTap;
  final VoidCallback onDeleteTap;

  const BarcodeCard({
    super.key,
    this.loyalty,
    this.identity,
    required this.cardType,
    required this.onCardTap,
    required this.onCopyTap,
    required this.onDeleteTap,
  }) : assert(loyalty != null || identity != null);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    const tapHint = "Tap to show barcode";

    // MODIFIED: Get data from the correct object
    final String cardName = cardType == BarcodeCardType.loyalty
        ? loyalty!.loyaltyName
        : identity!.identityName;
    final String cardNumber = cardType == BarcodeCardType.loyalty
        ? loyalty!.loyaltyNumber
        : identity!.identityNumber;
    final String? colorString = cardType == BarcodeCardType.loyalty
        ? loyalty!.color
        : identity!.color;

    // MODIFIED: Use saved color
    final Color cardColor = cardColors[colorString] ?? cardColors['default']!;

    return InkWell(
      onTap: onCardTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 180, // <-- FIXED: Added a fixed height to resolve layout error
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: cardColor, // MODIFIED
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withAlpha(51)),
          boxShadow: themeProvider.isDarkMode
              ? null
              : [
                  BoxShadow(
                    color: Colors.grey.withAlpha(26),
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
                      color: Colors.white, // MODIFIED
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'copy') {
                      onCopyTap();
                    } else if (value == 'delete') {
                      onDeleteTap();
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'copy',
                          child: ListTile(
                            leading: Icon(Icons.copy_outlined),
                            title: Text('Copy Number'),
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete_outline),
                            title: Text('Delete Card'),
                          ),
                        ),
                      ],
                  icon: const Icon(Icons.more_vert, color: Colors.white70),
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
                      color: Colors.white.withAlpha(204), // MODIFIED
                    )
                    .copyWith(fontFamily: 'ZSpace'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tapHint,
              style: themeProvider.getTextStyle(
                fontSize: 12,
                color: Colors.white.withAlpha(128), // MODIFIED
              ),
            ),
          ],
        ),
      ),
    );
  }
}
