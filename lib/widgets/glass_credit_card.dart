// lib/widgets/glass_credit_card.dart - ULTRA PREMIUM DESIGN

import 'package:flutter/material.dart';
import 'package:wallet/models/dataentry.dart';
import '../models/db_helper.dart';

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

  static final RegExp _fourDigitPattern = RegExp(r".{4}");

  String _formatCardNumber(String input) {
    return input.replaceAllMapped(
      _fourDigitPattern,
      (match) => "${match.group(0)} ",
    );
  }

  String _formatExpiry(String input) {
    if (input.length != 4) return "MM/YY";
    return "${input.substring(0, 2)}/${input.substring(2, 4)}";
  }

  @override
  Widget build(BuildContext context) {
    final lastFour = wallet.number.length >= 4
        ? wallet.number.substring(wallet.number.length - 4)
        : wallet.number;

    final String colorKey = wallet.color ?? 'obsidian';
    final CardColorData colorData =
        cardColorPalette[colorKey] ?? cardColorPalette['obsidian']!;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: onCardTap,
        child: AspectRatio(
          aspectRatio: 1.586, // Standard credit card ratio
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomRight,
                        colors: [
                          colorData.accent,
                          colorData.secondary,
                          colorData.primary,
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 20.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Chip & Contactless
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            Icons.contactless_rounded,
                            color: Colors.white.withValues(alpha: 0.784),
                            size: 32,
                          ),
                          SizedBox(
                            height: 36,
                            child: _NetworkLogo(network: wallet.network),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Card Number (Embossed Effect)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          isMasked
                              ? "••••  ••••  ••••  $lastFour"
                              : _formatCardNumber(wallet.number).trim(),
                          style: TextStyle(
                            fontFamily: 'Courier', // Monospace for numbers
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withValues(alpha: 0.941),
                            letterSpacing: 2.0,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.392),
                                offset: const Offset(1, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Footer: Name, Expiry, Logo
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              wallet.name.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),

                          // Expiry
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              isMasked ? "••/••" : _formatExpiry(wallet.expiry),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),

                          // Logo
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
    );
  }
}

class _NetworkLogo extends StatelessWidget {
  final String? network;

  const _NetworkLogo({required this.network});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      "assets/network/${network ?? 'visa'}.png",
      fit: BoxFit.contain,
      height: 30,
      color: Colors.white,
      errorBuilder: (context, error, stackTrace) {
        return Text(
          (network ?? 'CARD').toUpperCase(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontStyle: FontStyle.italic,
          ),
        );
      },
    );
  }
}
