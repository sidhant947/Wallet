// lib/widgets/glass_credit_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallet/models/dataentry.dart'; // FIXED: Import dataentry to access the color map
import '../models/db_helper.dart';
import '../models/theme_provider.dart';

class GlassCreditCard extends StatelessWidget {
  final Wallet wallet;
  final bool isMasked;
  final VoidCallback onCardTap;

  const GlassCreditCard({
    super.key,
    required this.wallet,
    required this.isMasked,
    required this.onCardTap,
  });

  String _formatCardNumber(String input) {
    return input.replaceAllMapped(
      RegExp(r".{4}"),
      (match) => "${match.group(0)} ",
    );
  }

  String _formatExpiry(String input) {
    if (input.length != 4) return "MM/YY";
    return "${input.substring(0, 2)}/${input.substring(2, 4)}";
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final lastFour = wallet.number.length >= 4
        ? wallet.number.substring(wallet.number.length - 4)
        : wallet.number;

    // --- FIXED: Updated color logic ---

    // 1. Check if a specific color has been selected for the card.
    final Color? selectedColor = cardColors[wallet.color];
    final bool hasCustomColor =
        selectedColor != null && wallet.color != 'default';

    // 2. Determine card and text colors based on the selection.
    bool isRupay = wallet.network?.toLowerCase() == 'rupay';

    final Color cardColor = hasCustomColor
        ? selectedColor // Use the selected color
        : isRupay
        ? Colors
              .black // Fallback for Rupay cards
        : (themeProvider.isDarkMode
              ? Colors.black
              : Colors.white); // Final fallback to the app theme

    // Text should be white on any dark or colored background.
    final bool useWhiteText =
        hasCustomColor || isRupay || themeProvider.isDarkMode;

    final textColor = useWhiteText ? Colors.white : Colors.black;
    final mutedTextColor = useWhiteText ? Colors.white70 : Colors.black54;

    // --- End of fix ---

    // final shadowColor = _getShadowColor(wallet.network);

    return GestureDetector(
      onTap: onCardTap,
      child: AspectRatio(
        aspectRatio: 1.586,
        child: Container(
          decoration: BoxDecoration(
            // borderRadius: BorderRadius.circular(10),
            // boxShadow: [
            //   BoxShadow(
            //     color: shadowColor.withAlpha(128),
            //     blurRadius: 25,
            //     spreadRadius: 0,
            //     offset: const Offset(0, 8),
            //   ),
            // ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor, // This now uses the corrected color
                border: Border.all(color: Colors.grey.withAlpha(51)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Image.asset(
                        "assets/network/${wallet.network}.png",
                        height: 35,
                        fit: BoxFit.contain,
                        color: (useWhiteText) && wallet.network == 'visa'
                            ? Colors.white
                            : null,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      key: ValueKey<bool>(isMasked),
                      child: Text(
                        isMasked
                            ? "**** **** **** $lastFour"
                            : _formatCardNumber(wallet.number),
                        style: TextStyle(
                          fontFamily: 'ZSpace',
                          fontSize: 28,
                          color: textColor, // Uses corrected text color
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          wallet.name.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: textColor, fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "EXPIRES",
                            style: TextStyle(
                              color:
                                  mutedTextColor, // Uses corrected text color
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            isMasked ? "••/••" : _formatExpiry(wallet.expiry),
                            style: TextStyle(color: textColor, fontSize: 18),
                          ),
                        ],
                      ),
                    ],
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
