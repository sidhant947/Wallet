// lib/widgets/glass_credit_card.dart - APPLE STYLE PREMIUM DESIGN

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

  String _formatCardNumber(String input) {
    if (input.isEmpty) return "";
    return input.replaceAllMapped(
      RegExp(r".{4}"),
      (match) => "${match.group(0)}  ",
    );
  }

  String _formatExpiry(String input) {
    if (input.length != 4) return "00/00";
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

    return GestureDetector(
      onTap: onCardTap,
      child: AspectRatio(
        aspectRatio: 1.586,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: colorData.primary.withOpacity(0.4),
                blurRadius: 25,
                offset: const Offset(0, 12),
                spreadRadius: -8,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // 1. Base Gradient (Mesh-like)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topLeft,
                        radius: 1.5,
                        colors: [
                          colorData.accent,
                          colorData.primary,
                          colorData.secondary,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                // 2. Subtle Noise/Texture Overlay
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.05,
                    child: Container(
                      decoration: const BoxDecoration(
                        // Simple noise simulation if desired, or just texture
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),

                // 3. Highlight/Sheen (Top Left)
                Positioned(
                  top: -100,
                  left: -100,
                  width: 300,
                  height: 300,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // 4. Content
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Top Row: Contactless Icon - Network Logo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            Icons.contactless_rounded,
                            color: Colors.white.withOpacity(0.9),
                            size: 32,
                          ),
                          SizedBox(
                            height: 28,
                            child: _NetworkLogo(network: wallet.network),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Card Number
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            isMasked
                                ? "••••  ••••  ••••  $lastFour"
                                : _formatCardNumber(wallet.number).trim(),
                            style: TextStyle(
                              fontFamily: 'SfPro',
                              fontSize: 22,
                              height: 1.0,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.0,
                              color: Colors.white.withOpacity(0.95),
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Bottom Row: Card Holder - Expires
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _buildCardInfo(
                              "Card Holder",
                              wallet.name.toUpperCase(),
                            ),
                          ),
                          const SizedBox(width: 24),
                          _buildCardInfo(
                            "Expires",
                            _formatExpiry(wallet.expiry),
                            crossAxis: CrossAxisAlignment.end,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 5. Glass Border (Inner Stroke)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardInfo(
    String label,
    String value, {
    CrossAxisAlignment crossAxis = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: crossAxis,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.7),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: crossAxis == CrossAxisAlignment.start
              ? Alignment.centerLeft
              : Alignment.centerRight,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
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
      color: Colors.white,
      errorBuilder: (context, error, stackTrace) {
        return Text(
          (network ?? 'VISA').toUpperCase(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontStyle: FontStyle.italic,
          ),
        );
      },
    );
  }
}
