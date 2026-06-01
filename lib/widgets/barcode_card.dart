import 'package:flutter/material.dart';
import 'package:wallet/models/db_helper.dart';

class BarcodeCard extends StatelessWidget {
  final Pass pass;
  final VoidCallback onCardTap;

  const BarcodeCard({
    super.key,
    required this.pass,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    switch (pass.type) {
      case 'boardingPass':
        return _BoardingPassLayout(pass: pass, onTap: onCardTap);
      case 'eventTicket':
        return _EventTicketLayout(pass: pass, onTap: onCardTap);
      case 'coupon':
        return _CouponLayout(pass: pass, onTap: onCardTap);
      case 'storeCard':
        return _StoreCardLayout(pass: pass, onTap: onCardTap);
      default:
        return _GenericPassLayout(pass: pass, onTap: onCardTap);
    }
  }
}

// Helper to parse CSS-like colors
Color _parseColor(String? colorString, Color fallback) {
  if (colorString == null) return fallback;
  try {
    if (colorString.startsWith('rgb')) {
      final match = RegExp(r'rgb\((\d+),\s*(\d+),\s*(\d+)\)').firstMatch(colorString.toLowerCase());
      if (match != null) {
        return Color.fromARGB(
          255,
          int.parse(match.group(1)!),
          int.parse(match.group(2)!),
          int.parse(match.group(3)!),
        );
      }
    } else if (colorString.startsWith('#')) {
      return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
    }
  } catch (e) {
    debugPrint('Error parsing color: $e');
  }
  return fallback;
}

// -----------------------------------------------------------------------------
// GENERIC PASS LAYOUT
// -----------------------------------------------------------------------------
class _GenericPassLayout extends StatelessWidget {
  final Pass pass;
  final VoidCallback onTap;

  const _GenericPassLayout({required this.pass, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(pass.backgroundColor, const Color(0xFF1E293B));
    final fgColor = _parseColor(pass.foregroundColor, Colors.white);
    final labelColor = _parseColor(pass.labelColor, Colors.white70);

    final List<dynamic> primaryFields = pass.fields?['primaryFields'] ?? [];
    final List<dynamic> secondaryFields = pass.fields?['secondaryFields'] ?? [];
    final List<dynamic> headerFields = pass.fields?['headerFields'] ?? [];

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1.586,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.4, 0.9, 1.0],
              colors: [
                bgColor,
                bgColor.withValues(alpha: 0.95),
                Color.alphaBlend(Colors.black38, bgColor),
                Color.alphaBlend(Colors.black54, bgColor),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: bgColor.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: -10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Subtle mesh-like glow
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          fgColor.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: fgColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.layers_rounded,
                                    color: fgColor.withValues(alpha: 0.9),
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    pass.organizationName.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: fgColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (headerFields.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  (headerFields[0]['label'] ?? '').toString().toUpperCase(),
                                  style: TextStyle(
                                    color: labelColor,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  (headerFields[0]['value'] ?? '').toString(),
                                  style: TextStyle(
                                    color: fgColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const Spacer(),
                      // Primary Content
                      if (primaryFields.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (primaryFields[0]['label'] ?? '').toString().toUpperCase(),
                              style: TextStyle(
                                color: labelColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (primaryFields[0]['value'] ?? '').toString(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: fgColor,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                height: 1.1,
                              ),
                            ),
                          ],
                        )
                      else if (pass.description != null && pass.description!.isNotEmpty)
                        Text(
                          pass.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: fgColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      const Spacer(),
                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                if (secondaryFields.isNotEmpty)
                                  ...secondaryFields.take(2).map((f) => Padding(
                                    padding: const EdgeInsets.only(right: 20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (f['label'] ?? '').toString().toUpperCase(),
                                          style: TextStyle(
                                            color: labelColor,
                                            fontSize: 7,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          (f['value'] ?? '').toString(),
                                          style: TextStyle(
                                            color: fgColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.qr_code_2_rounded,
                              color: Colors.black,
                              size: 28,
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
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// BOARDING PASS LAYOUT
// -----------------------------------------------------------------------------
class _BoardingPassLayout extends StatelessWidget {
  final Pass pass;
  final VoidCallback onTap;

  const _BoardingPassLayout({required this.pass, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(pass.backgroundColor, const Color(0xFF0F172A));
    final fgColor = _parseColor(pass.foregroundColor, Colors.white);
    final labelColor = _parseColor(pass.labelColor, Colors.white70);
    
    // Extract airport codes or labels
    String fromCode = "SFO";
    String toCode = "JFK";
    String fromName = "San Francisco";
    String toName = "New York";
    
    if (pass.fields?['primaryFields'] != null && (pass.fields!['primaryFields'] as List).isNotEmpty) {
      final list = pass.fields!['primaryFields'] as List;
      if (list.length >= 2) {
        fromCode = list[0]['value']?.toString() ?? 'SFO';
        fromName = list[0]['label']?.toString() ?? 'San Francisco';
        toCode = list[1]['value']?.toString() ?? 'JFK';
        toName = list[1]['label']?.toString() ?? 'New York';
      } else if (list.length == 1) {
        fromCode = list[0]['value']?.toString() ?? 'SFO';
        fromName = list[0]['label']?.toString() ?? 'San Francisco';
      }
    } else {
      // Use barcodeValue or organizationName to make a dynamic fallback
      if (pass.barcodeValue.contains('-')) {
        final parts = pass.barcodeValue.split('-');
        if (parts.length >= 2) {
          fromCode = parts[0].trim().toUpperCase();
          toCode = parts[1].trim().toUpperCase();
        }
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1.586,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                bgColor.withValues(alpha: 0.9),
                Color.alphaBlend(Colors.black87, bgColor).withValues(alpha: 0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Top flight light trail glow
                Positioned(
                  top: -60,
                  left: -60,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.03),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.airplane_ticket_rounded, color: fgColor.withValues(alpha: 0.8), size: 16),
                              const SizedBox(width: 8),
                              Text(
                                pass.organizationName.toUpperCase(),
                                style: TextStyle(
                                  color: fgColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          if (pass.logoText != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                pass.logoText!,
                                style: TextStyle(
                                  color: fgColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      // Large Airport Code Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fromCode,
                                  style: TextStyle(
                                    color: fgColor,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1,
                                  ),
                                ),
                                Text(
                                  fromName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: labelColor, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              children: [
                                Transform.rotate(
                                  angle: 1.5708, // 90 degrees right
                                  child: Icon(
                                    _getTransitIcon(pass.transitType),
                                    color: fgColor.withValues(alpha: 0.6),
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  toCode,
                                  style: TextStyle(
                                    color: fgColor,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1,
                                  ),
                                ),
                                Text(
                                  toName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: labelColor, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Ticket dashed line divider
                      Row(
                        children: List.generate(
                          30,
                          (index) => Expanded(
                            child: Container(
                              color: index % 2 == 0 ? Colors.transparent : fgColor.withValues(alpha: 0.15),
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Secondary Fields Row (Passenger, Gate, Flight, Seat)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (pass.fields?['secondaryFields'] != null)
                            ... (pass.fields!['secondaryFields'] as List).take(3).map((f) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (f['label'] ?? '').toString().toUpperCase(),
                                  style: TextStyle(color: labelColor, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  (f['value'] ?? '').toString(),
                                  style: TextStyle(color: fgColor, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ))
                          else ...[
                            // Elegant default boarding fields
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("PASSENGER", style: TextStyle(color: labelColor, fontSize: 8, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text("VALUED GUEST", style: TextStyle(color: fgColor, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text("GATE", style: TextStyle(color: labelColor, fontSize: 8, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text("B12", style: TextStyle(color: fgColor, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("SEAT", style: TextStyle(color: labelColor, fontSize: 8, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text("14A", style: TextStyle(color: fgColor, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
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

  IconData _getTransitIcon(String? type) {
    switch (type) {
      case 'PKTransitTypeAir': return Icons.flight_takeoff;
      case 'PKTransitTypeBoat': return Icons.directions_boat;
      case 'PKTransitTypeBus': return Icons.directions_bus;
      case 'PKTransitTypeRail': return Icons.directions_railway;
      default: return Icons.flight;
    }
  }
}

// -----------------------------------------------------------------------------
// EVENT TICKET LAYOUT
// -----------------------------------------------------------------------------
class _EventTicketLayout extends StatelessWidget {
  final Pass pass;
  final VoidCallback onTap;

  const _EventTicketLayout({required this.pass, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(pass.backgroundColor, const Color(0xFF4C1D95));
    final fgColor = _parseColor(pass.foregroundColor, Colors.white);
    final labelColor = _parseColor(pass.labelColor, Colors.white70);

    String eventTitle = "LIVE CONCERT EVENT";
    if (pass.fields?['primaryFields'] != null && (pass.fields!['primaryFields'] as List).isNotEmpty) {
      eventTitle = (pass.fields!['primaryFields'][0]['value'] ?? 'LIVE EVENT').toString();
    } else {
      if (pass.logoText != null) {
        eventTitle = pass.logoText!;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1.586,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                bgColor,
                Color.alphaBlend(Colors.black45, bgColor),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Glossy gradient highlight on top
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.05),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.2),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.confirmation_num_rounded, color: fgColor.withValues(alpha: 0.8), size: 14),
                              const SizedBox(width: 8),
                              Text(
                                pass.organizationName.toUpperCase(),
                                style: TextStyle(color: fgColor, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "ADMIT ONE",
                              style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      // Large Event Title
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            eventTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: fgColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              shadows: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          if (pass.description != null && pass.description!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Text(
                                pass.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: labelColor, fontSize: 9),
                              ),
                            ),
                        ],
                      ),
                      // Admission info section (Section, Row, Seat)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (pass.fields?['secondaryFields'] != null)
                              ... (pass.fields!['secondaryFields'] as List).take(3).map((f) => Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text((f['label'] ?? '').toString().toUpperCase(), style: TextStyle(color: labelColor, fontSize: 7, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                    Text((f['value'] ?? '').toString(), style: TextStyle(color: fgColor, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ))
                            else
                              const SizedBox.shrink(),
                            Icon(Icons.qr_code_scanner_rounded, color: fgColor.withValues(alpha: 0.6), size: 20),
                          ],
                        ),
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

// -----------------------------------------------------------------------------
// COUPON LAYOUT
// -----------------------------------------------------------------------------
class _CouponLayout extends StatelessWidget {
  final Pass pass;
  final VoidCallback onTap;

  const _CouponLayout({required this.pass, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(pass.backgroundColor, const Color(0xFF134E4A));
    final fgColor = _parseColor(pass.foregroundColor, Colors.white);
    final labelColor = _parseColor(pass.labelColor, Colors.white70);

    String offerValue = "50% OFF";
    if (pass.fields?['primaryFields'] != null && (pass.fields!['primaryFields'] as List).isNotEmpty) {
      offerValue = (pass.fields!['primaryFields'][0]['value'] ?? '50% OFF').toString();
    } else {
      if (pass.barcodeValue.isNotEmpty && pass.barcodeValue.length < 15) {
        offerValue = pass.barcodeValue;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1.586,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                bgColor,
                Color.alphaBlend(Colors.black54, bgColor),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Top-right discount tag background overlay
                Positioned(
                  right: -30,
                  top: -30,
                  child: Transform.rotate(
                    angle: -0.2,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                // Left Ticket Notch
                Positioned(
                  left: -10,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      width: 20,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0A),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                // Right Ticket Notch
                Positioned(
                  right: -10,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      width: 20,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0A),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.local_offer_rounded, color: fgColor.withValues(alpha: 0.8), size: 14),
                              const SizedBox(width: 6),
                              Text(
                                pass.organizationName.toUpperCase(),
                                style: TextStyle(
                                  color: fgColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: fgColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "COUPON",
                              style: TextStyle(
                                color: fgColor,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Large Offer Details
                      Column(
                        children: [
                          Text(
                            offerValue,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: fgColor,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                              shadows: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pass.description?.toUpperCase() ?? 'DISCOUNT VOUCHER',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: labelColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      // Coupon Expiry / Footer Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "VALID UNTIL",
                                style: TextStyle(color: labelColor, fontSize: 7, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                              ),
                              Text(
                                pass.relevantDate ?? "N/A",
                                style: TextStyle(color: fgColor, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                width: 1,
                                height: 20,
                                color: fgColor.withValues(alpha: 0.15),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.qr_code_2_rounded, color: fgColor.withValues(alpha: 0.7), size: 28),
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
    );
  }
}

// -----------------------------------------------------------------------------
// STORE CARD LAYOUT
// -----------------------------------------------------------------------------
class _StoreCardLayout extends StatelessWidget {
  final Pass pass;
  final VoidCallback onTap;

  const _StoreCardLayout({required this.pass, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(pass.backgroundColor, const Color(0xFF4C0519));
    final fgColor = _parseColor(pass.foregroundColor, Colors.white);
    final labelColor = _parseColor(pass.labelColor, Colors.white70);

    String points = "7,500";
    String tier = "GOLD MEMBER";
    
    if (pass.fields?['secondaryFields'] != null && (pass.fields!['secondaryFields'] as List).isNotEmpty) {
      final list = pass.fields!['secondaryFields'] as List;
      points = list[0]['value']?.toString() ?? '7,500';
      tier = list[0]['label']?.toString().toUpperCase() ?? 'LOYALTY MEMBER';
    } else {
      if (pass.description != null && pass.description!.isNotEmpty) {
        tier = pass.description!.toUpperCase();
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1.586,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                bgColor,
                Color.alphaBlend(Colors.black38, bgColor),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Soft background geometric grid circles
                Positioned(
                  bottom: -30,
                  right: -30,
                  child: Opacity(
                    opacity: 0.08,
                    child: Icon(Icons.stars_rounded, size: 180, color: fgColor),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.wallet_giftcard_rounded, color: fgColor.withValues(alpha: 0.8), size: 18),
                              const SizedBox(width: 6),
                              Text(
                                pass.organizationName.toUpperCase(),
                                style: TextStyle(color: fgColor, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2),
                              ),
                            ],
                          ),
                          Text(
                            tier,
                            style: TextStyle(color: labelColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                        ],
                      ),
                      // Dynamic points details
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "BALANCE",
                            style: TextStyle(color: labelColor, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                          ),
                          Row(
                            textBaseline: TextBaseline.alphabetic,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            children: [
                              Text(
                                points,
                                style: TextStyle(color: fgColor, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                              ),
                              const SizedBox(width: 4),
                              if (points != "---")
                                Text(
                                  "PTS",
                                  style: TextStyle(color: fgColor.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox.shrink(), // Replaced progress bar with empty space
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
