import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallet/models/db_helper.dart';
import '../models/theme_provider.dart';
import '../models/dataentry.dart';

class BarcodeCard extends StatelessWidget {
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
    final isDark = themeProvider.isDarkMode;
    const tapHint = "Tap to show barcode";

    // Get data from the correct object
    final String cardName = cardType == BarcodeCardType.loyalty
        ? loyalty!.loyaltyName
        : identity!.identityName;
    final String cardNumber = cardType == BarcodeCardType.loyalty
        ? loyalty!.loyaltyNumber
        : identity!.identityNumber;
    final String? colorString = cardType == BarcodeCardType.loyalty
        ? loyalty!.color
        : identity!.color;

    // Get color data from premium palette
    final String colorKey = colorString ?? 'obsidian';
    final CardColorData colorData =
        cardColorPalette[colorKey] ?? cardColorPalette['obsidian']!;

    // For light theme with default color, use a light variant
    final bool useLightCard =
        !isDark && (colorKey == 'default' || colorKey == 'obsidian');

    // Card gradient colors
    final Color primaryColor = useLightCard ? Colors.white : colorData.primary;
    final Color secondaryColor = useLightCard
        ? const Color(0xFFF5F5F5)
        : colorData.secondary;
    final Color accentColor = useLightCard
        ? const Color(0xFFE8E8E8)
        : colorData.accent;

    // Text colors
    final textColor = useLightCard ? Colors.black : Colors.white;
    final mutedTextColor = useLightCard
        ? Colors.black.withOpacity(0.5)
        : Colors.white.withOpacity(0.6);

    // Border color
    final borderColor = useLightCard
        ? Colors.black.withOpacity(0.08)
        : Colors.white.withOpacity(0.12);

    // Shadow color
    final shadowColor = useLightCard
        ? Colors.black.withOpacity(0.1)
        : colorData.secondary.withOpacity(0.4);

    return InkWell(
      onTap: onCardTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accentColor,
                    secondaryColor,
                    primaryColor,
                    primaryColor,
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Stack(
                children: [
                  // Glass shine effect at top
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(19),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            (useLightCard ? Colors.black : Colors.white)
                                .withOpacity(0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Card content
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
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
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: textColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'copy') {
                                    onCopyTap();
                                  } else if (value == 'delete') {
                                    onDeleteTap();
                                  }
                                },
                                itemBuilder: (BuildContext context) =>
                                    <PopupMenuEntry<String>>[
                                      PopupMenuItem<String>(
                                        value: 'copy',
                                        child: ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: Icon(
                                            Icons.copy_outlined,
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black54,
                                          ),
                                          title: Text(
                                            'Copy Number',
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'delete',
                                        child: ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: Icon(
                                            Icons.delete_outline,
                                            color: Colors.red.shade400,
                                          ),
                                          title: Text(
                                            'Delete Card',
                                            style: TextStyle(
                                              color: Colors.red.shade400,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                icon: Icon(
                                  Icons.more_vert,
                                  color: textColor.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Glass indicator line
                        Container(
                          height: 3,
                          width: 50,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: LinearGradient(
                              colors: [
                                textColor.withOpacity(0.4),
                                textColor.withOpacity(0.1),
                              ],
                            ),
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            cardNumber,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'ZSpace',
                              color: textColor.withOpacity(0.85),
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.touch_app_outlined,
                              size: 14,
                              color: mutedTextColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tapHint,
                              style: TextStyle(
                                fontSize: 12,
                                color: mutedTextColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
