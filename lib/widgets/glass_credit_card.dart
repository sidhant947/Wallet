// lib/widgets/glass_credit_card.dart - ULTRA PREMIUM DESIGN

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallet/models/dataentry.dart';
import '../models/db_helper.dart';
import '../models/theme_provider.dart';
import 'dart:math' as math;

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
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final lastFour = wallet.number.length >= 4
        ? wallet.number.substring(wallet.number.length - 4)
        : wallet.number;

    final String colorKey = wallet.color ?? 'obsidian';
    final CardColorData colorData =
        cardColorPalette[colorKey] ?? cardColorPalette['obsidian']!;

    final bool useLightCard =
        !isDark && (colorKey == 'default' || colorKey == 'obsidian');

    return RepaintBoundary(
      child: GestureDetector(
        onTap: onCardTap,
        child: AspectRatio(
          aspectRatio: 1.586, // Standard credit card ratio
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colorData.primary.withAlpha(80),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: -5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // 1. Dynamic Background Layer
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
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

                  // 2. Abstract Wave Pattern CustomPainter
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _AbstractWavePainter(
                        color: Colors.white.withAlpha(15),
                      ),
                    ),
                  ),

                  // 3. Noise/Grain Texture (Optional, simulated with dot pattern here for performance)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _NoisePatternPainter(
                        color: Colors.white.withAlpha(5),
                      ),
                    ),
                  ),

                  // 4. Glossy Reflection Overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withAlpha(useLightCard ? 150 : 30),
                            Colors.white.withAlpha(0),
                            Colors.black.withAlpha(useLightCard ? 0 : 40),
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // 5. Card Content
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
                            const _RealisticChip(),
                            Icon(
                              Icons.contactless_rounded,
                              color: Colors.white.withAlpha(200),
                              size: 32,
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
                              color: Colors.white.withAlpha(240),
                              letterSpacing: 2.0,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withAlpha(100),
                                  offset: const Offset(1, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Footer: Name, Expiry, Logo
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "CARD HOLDER",
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withAlpha(150),
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
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
                                ],
                              ),
                            ),

                            // Expiry
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "EXPIRES",
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withAlpha(150),
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isMasked
                                        ? "••/••"
                                        : _formatExpiry(wallet.expiry),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Logo
                            SizedBox(
                              height: 36,
                              child: _NetworkLogo(network: wallet.network),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 6. Border Highlight (The "Glass Edge")
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withAlpha(30),
                        width: 1.0,
                      ),
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

// Realistic EMV Chip Widget
class _RealisticChip extends StatelessWidget {
  const _RealisticChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 45,
      height: 35,
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37), // Metallic Gold
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF9E5BE), // Light gold
            Color(0xFFD4AF37), // Gold
            Color(0xFFC5A028), // Dark gold
            Color(0xFFF9E5BE), // Light gold highlight
          ],
          stops: [0.0, 0.4, 0.7, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 2,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: const CustomPaint(painter: _ChipCircuitPainter()),
    );
  }
}

class _ChipCircuitPainter extends CustomPainter {
  const _ChipCircuitPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withAlpha(50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final w = size.width;
    final h = size.height;

    // Rounded rectangle separation lines
    final rRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.2, h * 0.25, w * 0.6, h * 0.5),
      const Radius.circular(4),
    );
    canvas.drawRRect(rRect, paint);

    // Horizontal split
    canvas.drawLine(Offset(0, h * 0.5), Offset(w, h * 0.5), paint);

    // Vertical split sections
    canvas.drawLine(Offset(w * 0.35, h * 0.5), Offset(w * 0.35, h), paint);
    canvas.drawLine(Offset(w * 0.65, h * 0.5), Offset(w * 0.65, 0), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AbstractWavePainter extends CustomPainter {
  final Color color;

  const _AbstractWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.5,
      size.width * 0.5,
      size.height * 0.8,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 1.1,
      size.width,
      size.height * 0.6,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Second wave
    final path2 = Path();
    path2.moveTo(0, size.height * 0.4);
    path2.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.8,
      size.width,
      size.height * 0.2,
    );
    path2.lineTo(size.width, 0);
    path2.lineTo(0, 0);
    path2.close();

    paint.color = color.withAlpha(10); // Lighter
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NoisePatternPainter extends CustomPainter {
  final Color color;
  const _NoisePatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final random = math.Random(42); // Fixed seed for stability

    for (int i = 0; i < 200; i++) {
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        0.5 + random.nextDouble(), // Tiny dots
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NetworkLogo extends StatelessWidget {
  final String? network;

  const _NetworkLogo({required this.network});

  @override
  Widget build(BuildContext context) {
    // Force white colored logos for consistency on dark backgrounds
    return Image.asset(
      "assets/network/${network ?? 'visa'}.png",
      fit: BoxFit.contain,
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
