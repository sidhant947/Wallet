// lib/widgets/glass_credit_card.dart - ULTRA PREMIUM DESIGN

import 'dart:math' as math;
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
  bool _isFront = true;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _flipController,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    HapticFeedback.mediumImpact();
    if (_isFront) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() {
      _isFront = !_isFront;
    });
  }

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
    final lastFour = widget.wallet.number.length >= 4
        ? widget.wallet.number.substring(widget.wallet.number.length - 4)
        : widget.wallet.number;

    final String colorKey = widget.wallet.color ?? 'obsidian';
    final CardColorData colorData =
        cardColorPalette[colorKey] ?? cardColorPalette['obsidian']!;

    return Material(
      color: Colors.transparent,
      child: RepaintBoundary(
        child: GestureDetector(
          onTap: widget.onCardTap,
          onLongPress: _toggleFlip,
          child: AnimatedBuilder(
            animation: _flipAnimation,
            builder: (context, child) {
              final angle = _flipAnimation.value * math.pi;
              final isShowingBack = angle > math.pi / 2;
              
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                alignment: Alignment.center,
                child: isShowingBack
                    ? Transform(
                        transform: Matrix4.identity()..rotateY(math.pi),
                        alignment: Alignment.center,
                        child: _buildBack(colorData),
                      )
                    : _buildFront(colorData, lastFour),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFront(CardColorData colorData, String lastFour) {
    return AspectRatio(
      aspectRatio: 1.586,
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
                        child: _NetworkLogo(network: widget.wallet.network),
                      ),
                    ],
                  ),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.isMasked
                          ? "••••  ••••  ••••  $lastFour"
                          : _formatCardNumber(widget.wallet.number).trim(),
                      style: TextStyle(
                        fontFamily: 'Courier',
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          widget.wallet.name.toUpperCase(),
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          widget.isMasked
                              ? "••/••"
                              : _formatExpiry(widget.wallet.expiry),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
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
    );
  }

  Widget _buildBack(CardColorData colorData) {
    return AspectRatio(
      aspectRatio: 1.586,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomRight,
                    end: Alignment.topLeft,
                    colors: [
                      colorData.accent,
                      colorData.secondary,
                      colorData.primary,
                    ],
                  ),
                ),
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  height: 40,
                  width: double.infinity,
                  color: Colors.black.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          height: 35,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                widget.isMasked ? "•••" : "123",
                                style: const TextStyle(
                                  fontFamily: 'Courier',
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        flex: 1,
                        child: Text(
                          "CVV",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      "AUTHORIZED SIGNATURE",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
