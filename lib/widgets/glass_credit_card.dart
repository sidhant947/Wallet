// lib/widgets/glass_credit_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  Color _getShadowColor(String? network) {
    switch (network?.toLowerCase()) {
      case 'visa':
        return Colors.blue.shade700;
      case 'mastercard':
        return Colors.orange.shade800;
      case 'amex':
        return Colors.amber.shade700;
      case 'rupay':
        return Colors.green.shade600;
      case 'discover':
        return Colors.purple.shade700;
      default:
        return Colors.grey.shade500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final lastFour = wallet.number.length >= 4
        ? wallet.number.substring(wallet.number.length - 4)
        : wallet.number;

    // ** NEW LOGIC: Check for Rupay card first **
    bool isRupay = wallet.network?.toLowerCase() == 'rupay';

    final cardColor = isRupay
        ? Colors
              .black // Always black for Rupay
        : (themeProvider.isDarkMode ? Colors.black : Colors.white);

    final textColor = isRupay
        ? Colors
              .white // Always white text for Rupay
        : (themeProvider.isDarkMode ? Colors.white : Colors.black);

    final mutedTextColor = isRupay
        ? Colors
              .white70 // Always light grey text for Rupay
        : (themeProvider.isDarkMode ? Colors.white70 : Colors.black54);

    final shadowColor = _getShadowColor(wallet.network);

    return GestureDetector(
      onTap: onCardTap,
      child: AspectRatio(
        aspectRatio: 1.586,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withOpacity(0.5),
                blurRadius: 25,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
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
                        color:
                            (themeProvider.isDarkMode || isRupay) &&
                                wallet.network == 'visa'
                            ? Colors.white
                            : null,
                        errorBuilder: (context, _, __) => Text(
                          wallet.network?.toUpperCase() ?? "",
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
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
                          color: textColor,
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
                              color: mutedTextColor,
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
