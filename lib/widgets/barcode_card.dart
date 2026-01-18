import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:wallet/models/db_helper.dart';
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
    // Shared data extraction logic
    final String cardName = cardType == BarcodeCardType.loyalty
        ? loyalty!.loyaltyName
        : identity!.identityName;
    final String cardNumber = cardType == BarcodeCardType.loyalty
        ? loyalty!.loyaltyNumber
        : identity!.identityNumber;
    final String? colorString = cardType == BarcodeCardType.loyalty
        ? loyalty!.color
        : identity!.color;

    final String colorKey = colorString ?? 'obsidian';
    final CardColorData colorData =
        cardColorPalette[colorKey] ?? cardColorPalette['obsidian']!;

    if (cardType == BarcodeCardType.loyalty) {
      return _PremiumLoyaltyCard(
        name: cardName,
        number: cardNumber,
        colorData: colorData,
        onTap: onCardTap,
      );
    } else {
      return _PremiumIdentityCard(
        name: cardName,
        number: cardNumber,
        colorData: colorData,
        onTap: onCardTap,
      );
    }
  }
}

// -----------------------------------------------------------------------------
// PREMIUM LOYALTY CARD
// -----------------------------------------------------------------------------
class _PremiumLoyaltyCard extends StatelessWidget {
  final String name;
  final String number;
  final CardColorData colorData;
  final VoidCallback onTap;

  const _PremiumLoyaltyCard({
    required this.name,
    required this.number,
    required this.colorData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 1.586,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colorData.primary.withAlpha(80),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // 1. Background Gradient
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorData.secondary,
                            colorData.primary,
                            colorData.accent,
                          ],
                          stops: const [0.0, 0.6, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // 2. Stars / Rewards Pattern
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _RewardPatternPainter(
                        color: Colors.white.withAlpha(15),
                      ),
                    ),
                  ),

                  // 3. Floating Icon
                  Positioned(
                    top: -10,
                    right: -10,
                    child: Opacity(
                      opacity: 0.1,
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        size: 140,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // 4. Content
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(25),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withAlpha(50),
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.stars_rounded,
                                    color: Colors.white.withAlpha(230),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "LOYALTY",
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(230),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Program Name
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "REWARDS PROGRAM",
                              style: TextStyle(
                                color: Colors.white.withAlpha(128),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              name.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Card Number
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "MEMBERSHIP NUMBER",
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(128),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  number,
                                  style: TextStyle(
                                    fontFamily: 'Courier',
                                    color: Colors.white.withAlpha(230),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.qr_code_2_rounded,
                              color: Colors.white.withAlpha(150),
                              size: 32,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 5. Shine Effect
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withAlpha(25),
                            Colors.transparent,
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
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

class _RewardPatternPainter extends CustomPainter {
  final Color color;
  _RewardPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Use a fixed seed for consistency
    final random = math.Random(123);
    for (int i = 0; i < 30; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      double r = random.nextDouble() * 2 + 1;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -----------------------------------------------------------------------------
// PREMIUM IDENTITY CARD
// -----------------------------------------------------------------------------
class _PremiumIdentityCard extends StatelessWidget {
  final String name;
  final String number;
  final CardColorData colorData;
  final VoidCallback onTap;

  const _PremiumIdentityCard({
    required this.name,
    required this.number,
    required this.colorData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 1.586,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colorData.primary.withAlpha(80),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // 1. Background Gradient
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorData.secondary,
                            colorData.primary,
                            colorData.accent,
                          ],
                          stops: const [0.0, 0.6, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // 2. World Map / Security Pattern
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _WorldMapPainter(
                        color: Colors.white.withAlpha(15),
                      ),
                    ),
                  ),

                  // 3. Holographic Seal
                  Positioned(top: -20, right: -20, child: _HolographicSeal()),

                  // 4. Content
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(25),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withAlpha(50),
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.fingerprint,
                                    color: Colors.white.withAlpha(230),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "IDENTITY",
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(230),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Name
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "NAME",
                              style: TextStyle(
                                color: Colors.white.withAlpha(128),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              name.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ID Number
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "ID NUMBER",
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(128),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  number,
                                  style: TextStyle(
                                    fontFamily: 'Courier',
                                    color: Colors.white.withAlpha(230),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.qr_code_scanner_rounded,
                              color: Colors.white.withAlpha(80),
                              size: 32,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 5. Shine Effect
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withAlpha(25),
                            Colors.transparent,
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
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

class _HolographicSeal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Colors.white.withAlpha(25), Colors.white.withAlpha(0)],
        ),
      ),
      child: Center(
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withAlpha(25), width: 1),
          ),
          child: Center(
            child: Icon(
              Icons.shield_outlined,
              size: 40,
              color: Colors.white.withAlpha(25),
            ),
          ),
        ),
      ),
    );
  }
}

class _WorldMapPainter extends CustomPainter {
  final Color color;

  _WorldMapPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(0, h * 0.3);
    path.cubicTo(w * 0.3, h * 0.2, w * 0.7, h * 0.4, w, h * 0.2);

    path.moveTo(0, h * 0.6);
    path.cubicTo(w * 0.3, h * 0.5, w * 0.7, h * 0.7, w, h * 0.5);

    path.moveTo(w * 0.3, 0);
    path.cubicTo(w * 0.35, h * 0.5, w * 0.25, h, w * 0.3, h);

    path.moveTo(w * 0.7, 0);
    path.cubicTo(w * 0.65, h * 0.5, w * 0.75, h, w * 0.7, h);

    canvas.drawCircle(
      Offset(w * 0.3, h * 0.3),
      2,
      paint..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(w * 0.7, h * 0.6),
      2,
      paint..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.5),
      2,
      paint..style = PaintingStyle.fill,
    );

    canvas.drawPath(path, paint..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -----------------------------------------------------------------------------
// HELPERS & PAINTERS
// -----------------------------------------------------------------------------
