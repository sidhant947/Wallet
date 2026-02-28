// lib/widgets/glass_credit_card.dart - PERFORMANCE OPTIMIZED + PREMIUM ANIMATIONS

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallet/models/dataentry.dart';
import '../models/db_helper.dart';

class GlassCreditCard extends StatefulWidget {
  final Wallet wallet;
  final bool isMasked;
  final VoidCallback onCardTap;

  const GlassCreditCard({
    super.key,
    required this.wallet,
    required this.isMasked,
    required this.onCardTap,
  });

  @override
  State<GlassCreditCard> createState() => _GlassCreditCardState();
}

class _GlassCreditCardState extends State<GlassCreditCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

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
    final lastFour = widget.wallet.number.length >= 4
        ? widget.wallet.number.substring(widget.wallet.number.length - 4)
        : widget.wallet.number;

    final String colorKey = widget.wallet.color ?? 'obsidian';
    final CardColorData colorData =
        cardColorPalette[colorKey] ?? cardColorPalette['obsidian']!;

    return RepaintBoundary(
      child: GestureDetector(
        onTapDown: (_) {
          _pressController.forward();
          HapticFeedback.lightImpact();
        },
        onTapUp: (_) {
          _pressController.reverse();
          widget.onCardTap();
        },
        onTapCancel: () => _pressController.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Hero(
            tag: 'card_${widget.wallet.id ?? widget.wallet.number}',
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth;
                final cardHeight = cardWidth / 1.586;
                return SizedBox(
                  width: cardWidth,
                  height: cardHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: colorData.primary.withAlpha(150),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                          spreadRadius: -10,
                        ),
                        BoxShadow(
                          color: Colors.black.withAlpha(70),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          // 1. Base Gradient (Mesh-like)
                          Positioned.fill(
                            child: DecoratedBox(
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
                          const Positioned.fill(
                            child: Opacity(
                              opacity: 0.05,
                              child: DecoratedBox(
                                decoration: BoxDecoration(color: Colors.black),
                              ),
                            ),
                          ),

                          // 3. Premium Glass Highlight/Sheen
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  stops: const [0.0, 0.2, 0.4, 0.5, 0.55, 1.0],
                                  colors: [
                                    Colors.white.withAlpha(80),
                                    Colors.white.withAlpha(0),
                                    Colors.white.withAlpha(0),
                                    Colors.white.withAlpha(30),
                                    Colors.white.withAlpha(0),
                                    Colors.black.withAlpha(50),
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
                                // Top Row: Chip, Contactless - Network Logo
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 32,
                                      child: _NetworkLogo(
                                        network: widget.wallet.network,
                                      ),
                                    ),

                                    Icon(
                                      Icons.contactless_rounded,
                                      color: Colors.white.withAlpha(230),
                                      size: 30,
                                    ),
                                  ],
                                ),

                                const Spacer(),

                                // Card Number
                                FittedBox(
                                  child: Text(
                                    widget.isMasked
                                        ? "••••  ••••  ••••  $lastFour"
                                        : _formatCardNumber(
                                            widget.wallet.number,
                                          ).trim(),
                                    style: TextStyle(
                                      fontFamily: 'SfPro',
                                      fontSize: 22,
                                      height: 1.0,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 2.0,
                                      color: Colors.white.withAlpha(242),
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withAlpha(77),
                                          offset: const Offset(0, 1),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                Spacer(),

                                // Bottom Row: Card Holder - Expires
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: _buildCardInfo(
                                        "Card Holder",
                                        widget.wallet.name.toUpperCase(),
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    _buildCardInfo(
                                      "Expires",
                                      _formatExpiry(widget.wallet.expiry),
                                      crossAxis: CrossAxisAlignment.end,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // 5. Glass Border (Inner Stroke) highly polished
                          DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withAlpha(60),
                                width: 1.2,
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withAlpha(40),
                                  Colors.white.withAlpha(0),
                                  Colors.white.withAlpha(0),
                                  Colors.white.withAlpha(20),
                                ],
                                stops: const [0.0, 0.1, 0.9, 1.0],
                              ),
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
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
            color: Colors.white.withAlpha(179),
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
      cacheHeight: 56,
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

class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withAlpha(50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final path = Path();

    double w = size.width;
    double h = size.height;

    // Horizontal lines
    path.moveTo(0, h * 0.35);
    path.lineTo(w * 0.3, h * 0.35);
    path.lineTo(w * 0.3, 0);

    path.moveTo(w, h * 0.35);
    path.lineTo(w * 0.7, h * 0.35);
    path.lineTo(w * 0.7, 0);

    path.moveTo(0, h * 0.65);
    path.lineTo(w * 0.3, h * 0.65);
    path.lineTo(w * 0.3, h);

    path.moveTo(w, h * 0.65);
    path.lineTo(w * 0.7, h * 0.65);
    path.lineTo(w * 0.7, h);

    // Center oval / rectangle
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.35, h * 0.25, w * 0.3, h * 0.5),
        const Radius.circular(3),
      ),
      paint,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
