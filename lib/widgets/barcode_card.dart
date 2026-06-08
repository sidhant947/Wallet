import 'package:flutter/material.dart';
import 'package:wallet/models/db_helper.dart';
import 'package:wallet/services/barcode_utils.dart';
import 'package:wallet/models/card_color_data.dart';

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
    return RepaintBoundary(
      child: _buildLayout(context),
    );
  }

  Widget _buildLayout(BuildContext context) {
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
  } catch (_) {}
  return fallback;
}

// -----------------------------------------------------------------------------
// UTILS
// -----------------------------------------------------------------------------
String _getFieldValue(Map<String, dynamic>? fields, String label) {
  if (fields == null) return '';
  for (var section in fields.values) {
    if (section is List) {
      for (var field in section) {
        if (field['label']?.toString().toUpperCase() == label.toUpperCase()) {
          return field['value']?.toString() ?? '';
        }
      }
    }
  }
  return '';
}

// -----------------------------------------------------------------------------
// BASE PASS LAYOUT (Ensures no cropping, matches "perfect" generic look)
// -----------------------------------------------------------------------------
class _BasePassLayout extends StatelessWidget {
  final Pass pass;
  final VoidCallback onTap;
  final List<Widget> children;

  const _BasePassLayout({
    required this.pass,
    required this.onTap,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    // Attempt to find a matching premium color data
    CardColorData? matchingColorData;
    if (pass.backgroundColor != null) {
      final hex = pass.backgroundColor!.toLowerCase();
      for (var entry in cardColorPalette.entries) {
        final paletteHex = '#${(entry.value.primary.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
        if (hex == paletteHex.toLowerCase()) {
          matchingColorData = entry.value;
          break;
        }
      }
    }

    final bgColor = _parseColor(pass.backgroundColor, const Color(0xFF1E293B));
    final fgColor = _parseColor(pass.foregroundColor, Colors.white);

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1.586,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: matchingColorData != null
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      matchingColorData.accent,
                      matchingColorData.secondary,
                      matchingColorData.primary,
                    ],
                  )
                : LinearGradient(
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
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Mesh Glow
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [fgColor.withValues(alpha: 0.08), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...children,
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              BarcodeUtils.getIconForFormat(BarcodeUtils.getLabelFromFormat(pass.barcodeFormat)),
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
// GENERIC (Restored to "perfect" version)
// -----------------------------------------------------------------------------
class _GenericPassLayout extends StatelessWidget {
  final Pass pass;
  final VoidCallback onTap;
  const _GenericPassLayout({required this.pass, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fgColor = _parseColor(pass.foregroundColor, Colors.white);
    return _BasePassLayout(
      pass: pass,
      onTap: onTap,
      children: [
        Expanded(
          child: Text(
            pass.organizationName.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fgColor,
              fontWeight: FontWeight.w900,
              fontSize: 24,
              letterSpacing: 1.0,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// BOARDING PASS (New Best Version)
// -----------------------------------------------------------------------------
class _BoardingPassLayout extends StatelessWidget {
  final Pass pass;
  final VoidCallback onTap;
  const _BoardingPassLayout({required this.pass, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fgColor = _parseColor(pass.foregroundColor, Colors.white);
    final labelColor = fgColor.withValues(alpha: 0.5);
    final from = _getFieldValue(pass.fields, 'FROM');
    final to = _getFieldValue(pass.fields, 'TO');
    final flight = _getFieldValue(pass.fields, 'FLIGHT');

    return _BasePassLayout(
      pass: pass,
      onTap: onTap,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(pass.organizationName.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: fgColor, fontWeight: FontWeight.bold, fontSize: 12))),
            if (flight.isNotEmpty) Text('FLT $flight', style: TextStyle(color: fgColor, fontWeight: FontWeight.w900, fontSize: 12)),
          ],
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(from.isEmpty ? '---' : from, style: TextStyle(color: fgColor, fontSize: 32, fontWeight: FontWeight.w900)),
                Text('ORIGIN', style: TextStyle(color: labelColor, fontSize: 8, fontWeight: FontWeight.bold)),
              ],
            ),
            Icon(Icons.flight_takeoff_rounded, color: fgColor.withValues(alpha: 0.3), size: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(to.isEmpty ? '---' : to, style: TextStyle(color: fgColor, fontSize: 32, fontWeight: FontWeight.w900)),
                Text('DESTINATION', style: TextStyle(color: labelColor, fontSize: 8, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// EVENT TICKET (New Best Version)
// -----------------------------------------------------------------------------
class _EventTicketLayout extends StatelessWidget {
  final Pass pass;
  final VoidCallback onTap;
  const _EventTicketLayout({required this.pass, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fgColor = _parseColor(pass.foregroundColor, Colors.white);
    final event = _getFieldValue(pass.fields, 'EVENT');
    final date = _getFieldValue(pass.fields, 'DATE');
    final venue = _getFieldValue(pass.fields, 'VENUE');

    return _BasePassLayout(
      pass: pass,
      onTap: onTap,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(pass.organizationName.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: fgColor.withValues(alpha: 0.7), fontWeight: FontWeight.bold, fontSize: 10))),
            if (date.isNotEmpty) Text(date.toUpperCase(), style: TextStyle(color: fgColor, fontWeight: FontWeight.bold, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 12),
        Text(event.isEmpty ? pass.organizationName : event, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: fgColor, fontSize: 24, fontWeight: FontWeight.w900, height: 1.1)),
        const SizedBox(height: 4),
        Text(venue.isEmpty ? 'GENERAL ADMISSION' : venue.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: fgColor.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// STORE CARD (New Best Version)
// -----------------------------------------------------------------------------
class _StoreCardLayout extends StatelessWidget {
  final Pass pass;
  final VoidCallback onTap;
  const _StoreCardLayout({required this.pass, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fgColor = _parseColor(pass.foregroundColor, Colors.white);
    final balance = _getFieldValue(pass.fields, 'BALANCE');
    final tier = _getFieldValue(pass.fields, 'TIER');

    return _BasePassLayout(
      pass: pass,
      onTap: onTap,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(pass.organizationName.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: fgColor, fontWeight: FontWeight.w900, fontSize: 16))),
            if (tier.isNotEmpty) Text(tier.toUpperCase(), style: TextStyle(color: fgColor.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        const Spacer(),
        Text('BALANCE', style: TextStyle(color: fgColor.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        Flexible(
          child: Text(
            balance.isEmpty ? '---' : balance,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: fgColor, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// COUPON (New Best Version)
// -----------------------------------------------------------------------------
class _CouponLayout extends StatelessWidget {
  final Pass pass;
  final VoidCallback onTap;
  const _CouponLayout({required this.pass, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fgColor = _parseColor(pass.foregroundColor, Colors.white);
    final offer = _getFieldValue(pass.fields, 'OFFER');
    final expires = _getFieldValue(pass.fields, 'EXPIRES');

    return _BasePassLayout(
      pass: pass,
      onTap: onTap,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(pass.organizationName.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: fgColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1))),
            Icon(Icons.local_offer_rounded, color: fgColor.withValues(alpha: 0.5), size: 16),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: Column(
            children: [
              Text(offer.isEmpty ? 'SPECIAL OFFER' : offer, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: fgColor, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              if (expires.isNotEmpty) Text('EXPIRES $expires', style: TextStyle(color: fgColor.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}
