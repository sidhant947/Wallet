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
        onCopy: onCopyTap,
        onDelete: onDeleteTap,
      );
    } else {
      return _PremiumIdentityCard(
        name: cardName,
        number: cardNumber,
        colorData: colorData,
        onTap: onCardTap,
        onCopy: onCopyTap,
        onDelete: onDeleteTap,
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
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  const _PremiumLoyaltyCard({
    required this.name,
    required this.number,
    required this.colorData,
    required this.onTap,
    required this.onCopy,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 150,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Stack(
            children: [
              // 1. Main Card Body with Ticket Shape
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [colorData.primary, colorData.secondary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorData.primary.withAlpha(80),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        // Background Pattern
                        Positioned(
                          right: -50,
                          top: -50,
                          child: Icon(
                            Icons.stars_rounded,
                            size: 200,
                            color: Colors.white.withAlpha(10),
                          ),
                        ),

                        // Content Layout
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              // Details
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(30),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        "POINTS: --", // Placeholder for specific point tracking
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Right: Action Area
                              Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _GlassMenuButton(
                                    onCopy: onCopy,
                                    onDelete: onDelete,
                                  ),
                                  Icon(
                                    Icons.qr_code_2_rounded,
                                    color: Colors.white.withAlpha(200),
                                    size: 32,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Bottom "tear-off" section visual with dashed line
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(30),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.confirmation_number_outlined,
                                  color: Colors.white.withAlpha(150),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    number,
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(200),
                                      fontSize: 14,
                                      fontFamily: 'Courier',
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PREMIUM IDENTITY CARD
// -----------------------------------------------------------------------------
class _PremiumIdentityCard extends StatelessWidget {
  final String name;
  final String number;
  final CardColorData colorData;
  final VoidCallback onTap;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  const _PremiumIdentityCard({
    required this.name,
    required this.number,
    required this.colorData,
    required this.onTap,
    required this.onCopy,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 160, // Slightly taller for ID
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white, // Most IDs have white/light base
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // 1. Guilloche Security Pattern (CustomPainter)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _GuillochePainter(
                      color: colorData.primary.withAlpha(15),
                    ),
                  ),
                ),

                // 2. Holographic Strip (Gradient)
                Positioned(
                  left: 20,
                  top: 0,
                  bottom: 0,
                  width: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colorData.primary,
                          colorData.accent,
                          Colors.cyanAccent,
                          colorData.primary,
                        ],
                      ),
                    ),
                  ),
                ),

                // 4. Header & Details
                Positioned(
                  left: 35,
                  top: 20,
                  right: 20,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorData.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "OFFICIAL ID",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          _LightMenuButton(onCopy: onCopy, onDelete: onDelete),
                        ],
                      ),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name Label
                          Text(
                            "NAME",
                            style: TextStyle(
                              color: colorData.secondary.withAlpha(150),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            name.toUpperCase(),
                            style: TextStyle(
                              color: colorData.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Number Label
                          Text(
                            "ID NUMBER",
                            style: TextStyle(
                              color: colorData.secondary.withAlpha(150),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              number,
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontFamily: 'Courier',
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 5. Watermark / Overlay (Secure Stamp)
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Opacity(
                    opacity: 0.1,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: colorData.primary, width: 10),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.security,
                          size: 80,
                          color: colorData.primary,
                        ),
                      ),
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
}

// -----------------------------------------------------------------------------
// HELPERS & PAINTERS
// -----------------------------------------------------------------------------

class _GlassMenuButton extends StatelessWidget {
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  const _GlassMenuButton({required this.onCopy, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'copy') onCopy();
        if (value == 'delete') onDelete();
      },
      icon: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(30),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.more_horiz, color: Colors.white, size: 20),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'copy', child: Text('Copy Number')),
        PopupMenuItem(
          value: 'delete',
          child: Text('Delete', style: TextStyle(color: Colors.red.shade400)),
        ),
      ],
    );
  }
}

class _LightMenuButton extends StatelessWidget {
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  const _LightMenuButton({required this.onCopy, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'copy') onCopy();
        if (value == 'delete') onDelete();
      },
      icon: Icon(Icons.more_horiz, color: Colors.grey.shade400, size: 24),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'copy', child: Text('Copy Number')),
        PopupMenuItem(
          value: 'delete',
          child: Text('Delete', style: TextStyle(color: Colors.red.shade400)),
        ),
      ],
    );
  }
}

class _GuillochePainter extends CustomPainter {
  final Color color;
  _GuillochePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final cx = size.width / 2;
    final cy = size.height / 2;

    for (double i = 0; i < size.width; i += 10) {
      final path = Path();
      path.moveTo(i, 0);
      path.quadraticBezierTo(cx, cy, size.width - i, size.height);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
