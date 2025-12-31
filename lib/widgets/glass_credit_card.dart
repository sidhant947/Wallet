// lib/widgets/glass_credit_card.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallet/models/dataentry.dart';
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
    final isDark = themeProvider.isDarkMode;
    final lastFour = wallet.number.length >= 4
        ? wallet.number.substring(wallet.number.length - 4)
        : wallet.number;

    // Get the color data from the premium palette
    final String colorKey = wallet.color ?? 'obsidian';
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

    // Border color with glass effect
    final borderColor = useLightCard
        ? Colors.black.withOpacity(0.08)
        : Colors.white.withOpacity(0.12);

    // Shadow color based on card color
    final shadowColor = useLightCard
        ? Colors.black.withOpacity(0.1)
        : colorData.secondary.withOpacity(0.4);

    return GestureDetector(
      onTap: onCardTap,
      child: AspectRatio(
        aspectRatio: 1.586,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 30,
                offset: const Offset(0, 12),
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
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    // Glass shine effect at top
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 80,
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
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row with glass chip and network logo
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Glass chip indicator
                              Container(
                                width: 50,
                                height: 38,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      textColor.withOpacity(0.25),
                                      textColor.withOpacity(0.1),
                                      textColor.withOpacity(0.05),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: textColor.withOpacity(0.15),
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    // Chip lines
                                    Positioned(
                                      left: 10,
                                      top: 8,
                                      bottom: 8,
                                      child: Container(
                                        width: 1,
                                        color: textColor.withOpacity(0.2),
                                      ),
                                    ),
                                    Positioned(
                                      left: 16,
                                      top: 8,
                                      bottom: 8,
                                      child: Container(
                                        width: 1,
                                        color: textColor.withOpacity(0.2),
                                      ),
                                    ),
                                    Positioned(
                                      top: 12,
                                      left: 8,
                                      right: 8,
                                      child: Container(
                                        height: 1,
                                        color: textColor.withOpacity(0.2),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 12,
                                      left: 8,
                                      right: 8,
                                      child: Container(
                                        height: 1,
                                        color: textColor.withOpacity(0.2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Image.asset(
                                "assets/network/${wallet.network}.png",
                                height: 35,
                                fit: BoxFit.contain,
                                color: !useLightCard && wallet.network == 'visa'
                                    ? Colors.white
                                    : null,
                                errorBuilder: (context, error, stackTrace) {
                                  return const SizedBox.shrink();
                                },
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Card number
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
                                  fontSize: 26,
                                  color: textColor,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Bottom row with name and expiry
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Text(
                                  wallet.name.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
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
                                      fontSize: 9,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isMasked
                                        ? "••/••"
                                        : _formatExpiry(wallet.expiry),
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
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
      ),
    );
  }
}
