import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:wallet/models/db_helper.dart';
import 'package:wallet/services/barcode_utils.dart';
import 'package:wallet/models/pass_types.dart';
import 'package:wallet/widgets/encrypted_image_display.dart';

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
      case 'loyaltyCard':
        return _LoyaltyCardLayout(pass: pass, onTap: onCardTap);
      case 'giftCard':
        return _GiftCardLayout(pass: pass, onTap: onCardTap);
      case 'offer':
        return _OfferLayout(pass: pass, onTap: onCardTap);
      case 'transitPass':
        return _TransitPassLayout(pass: pass, onTap: onCardTap);
      case 'healthInsuranceCard':
        return _HealthInsuranceLayout(pass: pass, onTap: onCardTap);
      case 'healthTestRecord':
        return _HealthTestLayout(pass: pass, onTap: onCardTap);
      case 'healthVaccineCard':
        return _VaccineCardLayout(pass: pass, onTap: onCardTap);
      case 'digitalCarKey':
        return _CarKeyLayout(pass: pass, onTap: onCardTap);
      case 'campusId':
        return _CampusIdLayout(pass: pass, onTap: onCardTap);
      case 'corporateBadge':
        return _CorporateBadgeLayout(pass: pass, onTap: onCardTap);
      case 'hotelKey':
        return _HotelKeyLayout(pass: pass, onTap: onCardTap);
      case 'multiFamilyKey':
        return _MultiFamilyKeyLayout(pass: pass, onTap: onCardTap);
      case 'digitalCredential':
        return _DigitalCredentialLayout(pass: pass, onTap: onCardTap);
      case 'genericPrivate':
        return _GenericPrivateLayout(pass: pass, onTap: onCardTap);
      case 'inStorePayment':
        return _InStorePaymentLayout(pass: pass, onTap: onCardTap);
      default:
        return _GenericPassLayout(pass: pass, onTap: onCardTap);
    }
  }
}

// -----------------------------------------------------------------------------
// UTILS
// -----------------------------------------------------------------------------
Color _parseColor(String? colorString, Color fallback) {
  if (colorString == null) return fallback;
  try {
    if (colorString.startsWith('#')) {
      return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
    }
  } catch (_) {}
  return fallback;
}

Color _getContrastingColor(Color bg) {
  final luminance = bg.computeLuminance();
  return luminance > 0.5 ? Colors.black : Colors.white;
}

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
// GOOGLE WALLET BASE LAYOUT
// -----------------------------------------------------------------------------
class _GoogleWalletBaseLayout extends StatelessWidget {
  final Pass pass;
  final VoidCallback onTap;
  final List<Widget> fieldRows;
  final IconData? titleIcon;

  const _GoogleWalletBaseLayout({
    required this.pass,
    required this.onTap,
    required this.fieldRows,
    this.titleIcon,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(pass.backgroundColor, const Color(0xFF1E293B));
    final textColor = _getContrastingColor(bgColor);
    final mutedColor = textColor.withValues(alpha: 0.6);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: const BoxConstraints(minHeight: 180),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Card Title: Logo + Org Name + Program Name
                Row(
                  children: [
                    _buildLogo(textColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pass.organizationName.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: mutedColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          if (pass.logoText != null && pass.logoText!.isNotEmpty)
                            Text(
                              pass.logoText!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (titleIcon != null)
                      Icon(titleIcon, color: mutedColor, size: 18),
                  ],
                ),

                // Field Rows
                if (fieldRows.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...fieldRows,
                ],

                // Barcode Section
                if (pass.barcodeValue.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildBarcodeSection(textColor, mutedColor),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(Color textColor) {
    if (pass.frontImagePath != null && pass.frontImagePath!.isNotEmpty) {
      return ClipOval(
        child: EncryptedImageDisplay(
          imagePath: pass.frontImagePath!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorWidget: _buildDefaultLogo(textColor),
        ),
      );
    }
    return _buildDefaultLogo(textColor);
  }

  Widget _buildDefaultLogo(Color textColor) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        PassType.fromValue(pass.type).icon,
        color: textColor.withValues(alpha: 0.8),
        size: 20,
      ),
    );
  }

  Widget _buildBarcodeSection(Color textColor, Color mutedColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: BarcodeWidget(
            barcode: BarcodeUtils.getBarcodeFromFormat(pass.barcodeFormat),
            data: pass.barcodeValue,
            color: Colors.black,
            height: 60,
            width: double.infinity,
            errorBuilder: (context, error) => Center(
              child: Text(
                'Invalid Barcode',
                style: TextStyle(color: Colors.red.shade700, fontSize: 10),
              ),
            ),
          ),
        ),
        if (pass.barcodeAltText != null && pass.barcodeAltText!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              pass.barcodeAltText!,
              style: TextStyle(
                color: mutedColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// FIELD ROW WIDGETS
// -----------------------------------------------------------------------------
class _GWSingleRow extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;

  const _GWSingleRow({
    required this.label,
    required this.value,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: textColor.withValues(alpha: 0.5),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _GWTwoItemRow extends StatelessWidget {
  final String startLabel;
  final String startValue;
  final String endLabel;
  final String endValue;
  final Color textColor;

  const _GWTwoItemRow({
    required this.startLabel,
    required this.startValue,
    required this.endLabel,
    required this.endValue,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (startValue.isEmpty && endValue.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: _buildItem(startLabel, startValue)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _buildItemChildren(endLabel, endValue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildItemChildren(label, value),
    );
  }

  List<Widget> _buildItemChildren(String label, String value) {
    if (value.isEmpty) return [const SizedBox.shrink()];
    return [
      Text(
        label.toUpperCase(),
        style: TextStyle(
          color: textColor.withValues(alpha: 0.5),
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ];
  }
}

class _GWThreeItemRow extends StatelessWidget {
  final String startLabel;
  final String startValue;
  final String middleLabel;
  final String middleValue;
  final String endLabel;
  final String endValue;
  final Color textColor;

  const _GWThreeItemRow({
    required this.startLabel,
    required this.startValue,
    required this.middleLabel,
    required this.middleValue,
    required this.endLabel,
    required this.endValue,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (startValue.isEmpty && middleValue.isEmpty && endValue.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: _buildItem(startLabel, startValue)),
          const SizedBox(width: 12),
          Expanded(child: _buildItem(middleLabel, middleValue)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _buildItemChildren(endLabel, endValue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildItemChildren(label, value),
    );
  }

  List<Widget> _buildItemChildren(String label, String value) {
    if (value.isEmpty) return [const SizedBox.shrink()];
    return [
      Text(
        label.toUpperCase(),
        style: TextStyle(
          color: textColor.withValues(alpha: 0.5),
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ];
  }
}

// -----------------------------------------------------------------------------
// GENERIC PASS
// -----------------------------------------------------------------------------
class _GenericPassLayout extends StatelessWidget {
  final Pass pass;
  final VoidCallback onTap;
  const _GenericPassLayout({required this.pass, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(pass.backgroundColor, const Color(0xFF1E293B));
    final textColor = _getContrastingColor(bgColor);
    final details = _getFieldValue(pass.fields, 'DETAILS');
    final date = _getFieldValue(pass.fields, 'DATE');

    return _GoogleWalletBaseLayout(
      pass: pass,
      onTap: onTap,
      fieldRows: [
        if (details.isNotEmpty)
          _GWSingleRow(label: 'Details', value: details, textColor: textColor),
        _GWTwoItemRow(
          startLabel: 'Date', startValue: date,
          endLabel: '', endValue: '',
          textColor: textColor,
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// LOYALTY CARD
// -----------------------------------------------------------------------------
class _LoyaltyCardLayout extends StatelessWidget {
  final Pass pass;
  final VoidCallback onTap;
  const _LoyaltyCardLayout({required this.pass, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(pass.backgroundColor, const Color(0xFF1E293B));
    final textColor = _getContrastingColor(bgColor);
    final memberName = _getFieldValue(pass.fields, 'MEMBER NAME');
    final balance = _getFieldValue(pass.fields, 'BALANCE');
    final tier = _getFieldValue(pass.fields, 'TIER');
    final points = _getFieldValue(pass.fields, 'POINTS');
    final accountNum = _getFieldValue(pass.fields, 'ACCOUNT #');

    return _GoogleWalletBaseLayout(
      pass: pass,
      onTap: onTap,
      fieldRows: [
        _GWSingleRow(label: 'Member Name', value: memberName, textColor: textColor),
        _GWThreeItemRow(
          startLabel: 'Balance', startValue: balance,
          middleLabel: 'Points', middleValue: points,
          endLabel: 'Tier', endValue: tier,
          textColor: textColor,
        ),
        _GWSingleRow(label: 'Account #', value: accountNum, textColor: textColor),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// GIFT CARD
// -----------------------------------------------------------------------------
class _GiftCardLayout extends StatelessWidget {
  final Pass pass;
  final VoidCallback onTap;
  const _GiftCardLayout({required this.pass, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(pass.backgroundColor, const Color(0xFF1E293B));
    final textColor = _getContrastingColor(bgColor);
    final cardNumber = _getFieldValue(pass.fields, 'CARD NUMBER');
    final balance = _getFieldValue(pass.fields, 'BALANCE');
    final pin = _getFieldValue(pass.fields, 'PIN');
    final recipient = _getFieldValue(pass.fields, 'RECIPIENT');

    return _GoogleWalletBaseLayout(
      pass: pass,
      onTap: onTap,
      fieldRows: [
        _GWSingleRow(label: 'Card Number', value: cardNumber, textColor: textColor),
        _GWThreeItemRow(
          startLabel: 'Balance', startValue: balance,
          middleLabel: 'PIN', middleValue: pin,
          endLabel: 'Recipient', endValue: recipient,
          textColor: textColor,
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// OFFER
// -----------------------------------------------------------------------------
class _OfferLayout extends StatelessWidget {
  final Pass pass;
  final VoidCallback onTap;
  const _OfferLayout({required this.pass, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(pass.backgroundColor, const Color(0xFF1E293B));
    final textColor = _getContrastingColor(bgColor);
    final offerTitle = _getFieldValue(pass.fields, 'OFFER');
    final provider = _getFieldValue(pass.fields, 'PROVIDER');
    final expires = _getFieldValue(pass.fields, 'EXPIRES');
    final code = _getFieldValue(pass.fields, 'CODE');

    return _GoogleWalletBaseLayout(
      pass: pass,
      onTap: onTap,
      titleIcon: Icons.local_offer_rounded,
      fieldRows: [
        if (offerTitle.isNotEmpty)
          _GWSingleRow(label: 'Offer', value: offerTitle, textColor: textColor),
        _GWTwoItemRow(
          startLabel: 'Provider', startValue: provider,
          endLabel: 'Expires', endValue: expires,
          textColor: textColor,
        ),
        if (code.isNotEmpty)
          _GWSingleRow(label: 'Code', value: code, textColor: textColor),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// BOARDING PASS
// -----------------------------------------------------------------------------
class _BoardingPassLayout extends StatelessWidget {
  final Pass pass;
  final VoidCallback onTap;
  const _BoardingPassLayout({required this.pass, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(pass.backgroundColor, const Color(0xFF1E293B));
    final textColor = _getContrastingColor(bgColor);
    final from = _getFieldValue(pass.fields, 'FROM');
    final to = _getFieldValue(pass.fields, 'TO');
    final flight = _getFieldValue(pass.fields, 'FLIGHT');
    final gate = _getFieldValue(pass.fields, 'GATE');
    final seat = _getFieldValue(pass.fields, 'SEAT');
    final departure = _getFieldValue(pass.fields, 'DEPARTURE');
    final arrival = _getFieldValue(pass.fields, 'ARRIVAL');

    return _GoogleWalletBaseLayout(
      pass: pass,
      onTap: onTap,
      titleIcon: Icons.flight_rounded,
      fieldRows: [
        // FROM → TO row (large)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FROM', style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    const SizedBox(height: 2),
                    Text(from.isEmpty ? '---' : from, style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              Icon(Icons.flight_takeoff_rounded, color: textColor.withValues(alpha: 0.3), size: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('TO', style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    const SizedBox(height: 2),
                    Text(to.isEmpty ? '---' : to, style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
        ),
        _GWThreeItemRow(
          startLabel: 'Flight', startValue: flight,
          middleLabel: 'Gate', middleValue: gate,
          endLabel: 'Seat', endValue: seat,
          textColor: textColor,
        ),
        _GWTwoItemRow(
          startLabel: 'Departure', startValue: departure,
          endLabel: 'Arrival', endValue: arrival,
          textColor: textColor,
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// EVENT TICKET
// -----------------------------------------------------------------------------
class _EventTicketLayout extends StatelessWidget {
  final Pass pass;
  final VoidCallback onTap;
  const _EventTicketLayout({required this.pass, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(pass.backgroundColor, const Color(0xFF1E293B));
    final textColor = _getContrastingColor(bgColor);
    final event = _getFieldValue(pass.fields, 'EVENT');
    final venue = _getFieldValue(pass.fields, 'VENUE');
    final date = _getFieldValue(pass.fields, 'DATE');
    final section = _getFieldValue(pass.fields, 'SECTION');
    final row = _getFieldValue(pass.fields, 'ROW');
    final seat = _getFieldValue(pass.fields, 'SEAT');
    final time = _getFieldValue(pass.fields, 'TIME');

    return _GoogleWalletBaseLayout(
      pass: pass,
      onTap: onTap,
      titleIcon: Icons.confirmation_number_rounded,
      fieldRows: [
        if (event.isNotEmpty)
          _GWSingleRow(label: 'Event', value: event, textColor: textColor),
        _GWTwoItemRow(
          startLabel: 'Venue', startValue: venue,
          endLabel: 'Date', endValue: date,
          textColor: textColor,
        ),
        _GWThreeItemRow(
          startLabel: 'Section', startValue: section,
          middleLabel: 'Row', middleValue: row,
          endLabel: 'Seat', endValue: seat,
          textColor: textColor,
        ),
        if (time.isNotEmpty)
          _GWSingleRow(label: 'Time', value: time, textColor: textColor),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// TRANSIT PASS
// -----------------------------------------------------------------------------
class _TransitPassLayout extends StatelessWidget {
  final Pass pass;
  final VoidCallback onTap;
  const _TransitPassLayout({required this.pass, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(pass.backgroundColor, const Color(0xFF1E293B));
    final textColor = _getContrastingColor(bgColor);
    final from = _getFieldValue(pass.fields, 'FROM');
    final to = _getFieldValue(pass.fields, 'TO');
    final route = _getFieldValue(pass.fields, 'ROUTE');
    final fareClass = _getFieldValue(pass.fields, 'FARE CLASS');
    final seat = _getFieldValue(pass.fields, 'SEAT');
    final coach = _getFieldValue(pass.fields, 'COACH');
    final platform = _getFieldValue(pass.fields, 'PLATFORM');

    final transitType = pass.transitType ?? 'BUS';
    IconData transitIcon;
    switch (transitType.toUpperCase()) {
      case 'RAIL': case 'TRAIN': transitIcon = Icons.train_rounded; break;
      case 'TRAM': transitIcon = Icons.tram_rounded; break;
      case 'FERRY': transitIcon = Icons.directions_boat_rounded; break;
      default: transitIcon = Icons.directions_bus_rounded;
    }

    return _GoogleWalletBaseLayout(
      pass: pass,
      onTap: onTap,
      titleIcon: transitIcon,
      fieldRows: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FROM', style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    const SizedBox(height: 2),
                    Text(from.isEmpty ? '---' : from, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: textColor.withValues(alpha: 0.3), size: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('TO', style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    const SizedBox(height: 2),
                    Text(to.isEmpty ? '---' : to, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
        ),
        _GWThreeItemRow(
          startLabel: 'Route', startValue: route,
          middleLabel: 'Fare', middleValue: fareClass,
          endLabel: 'Platform', endValue: platform,
          textColor: textColor,
        ),
        _GWTwoItemRow(
          startLabel: 'Seat', startValue: seat,
          endLabel: 'Coach', endValue: coach,
          textColor: textColor,
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// HEALTH INSURANCE CARD
// -----------------------------------------------------------------------------
class _HealthInsuranceLayout extends StatelessWidget {
  final Pass pass;
  final VoidCallback onTap;
  const _HealthInsuranceLayout({required this.pass, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(pass.backgroundColor, const Color(0xFF1E293B));
    final textColor = _getContrastingColor(bgColor);
    final memberName = _getFieldValue(pass.fields, 'MEMBER NAME');
    final policyNumber = _getFieldValue(pass.fields, 'POLICY #');
    final provider = _getFieldValue(pass.fields, 'PROVIDER');
    final groupNumber = _getFieldValue(pass.fields, 'GROUP #');
    final pcn = _getFieldValue(pass.fields, 'PCN');

    return _GoogleWalletBaseLayout(
      pass: pass,
      onTap: onTap,
      titleIcon: Icons.health_and_safety_rounded,
      fieldRows: [
        _GWSingleRow(label: 'Member Name', value: memberName, textColor: textColor),
        _GWTwoItemRow(
          startLabel: 'Provider', startValue: provider,
          endLabel: 'Policy #', endValue: policyNumber,
          textColor: textColor,
        ),
        _GWThreeItemRow(
          startLabel: 'Group #', startValue: groupNumber,
          middleLabel: 'PCN', middleValue: pcn,
          endLabel: '', endValue: '',
          textColor: textColor,
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// HEALTH TEST RECORD
// -----------------------------------------------------------------------------
class _HealthTestLayout extends StatelessWidget {
  final Pass pass;
  final VoidCallback onTap;
  const _HealthTestLayout({required this.pass, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(pass.backgroundColor, const Color(0xFF1E293B));
    final textColor = _getContrastingColor(bgColor);
    final testType = _getFieldValue(pass.fields, 'TEST TYPE');
    final result = _getFieldValue(pass.fields, 'RESULT');
    final date = _getFieldValue(pass.fields, 'DATE');
    final lab = _getFieldValue(pass.fields, 'LAB');
    final provider = _getFieldValue(pass.fields, 'PROVIDER');

    return _GoogleWalletBaseLayout(
      pass: pass,
      onTap: onTap,
      titleIcon: Icons.science_rounded,
      fieldRows: [
        _GWSingleRow(label: 'Test Type', value: testType, textColor: textColor),
        _GWTwoItemRow(
          startLabel: 'Result', startValue: result,
          endLabel: 'Date', endValue: date,
          textColor: textColor,
        ),
        _GWTwoItemRow(
          startLabel: 'Lab', startValue: lab,
          endLabel: 'Provider', endValue: provider,
          textColor: textColor,
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// VACCINE CARD
// -----------------------------------------------------------------------------
class _VaccineCardLayout extends StatelessWidget {
  final Pass pass;
  final VoidCallback onTap;
  const _VaccineCardLayout({required this.pass, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(pass.backgroundColor, const Color(0xFF1E293B));
    final textColor = _getContrastingColor(bgColor);
    final vaccine = _getFieldValue(pass.fields, 'VACCINE');
    final dose = _getFieldValue(pass.fields, 'DOSE');
    final date = _getFieldValue(pass.fields, 'DATE');
    final manufacturer = _getFieldValue(pass.fields, 'MANUFACTURER');
    final lotNumber = _getFieldValue(pass.fields, 'LOT #');

    return _GoogleWalletBaseLayout(
      pass: pass,
      onTap: onTap,
      titleIcon: Icons.vaccines_rounded,
      fieldRows: [
        _GWSingleRow(label: 'Vaccine', value: vaccine, textColor: textColor),
        _GWTwoItemRow(
          startLabel: 'Dose', startValue: dose,
          endLabel: 'Date', endValue: date,
          textColor: textColor,
        ),
        _GWTwoItemRow(
          startLabel: 'Manufacturer', startValue: manufacturer,
          endLabel: 'Lot #', endValue: lotNumber,
          textColor: textColor,
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// DIGITAL CAR KEY
// -----------------------------------------------------------------------------
class _CarKeyLayout extends StatelessWidget {
  final Pass pass;
  final VoidCallback onTap;
  const _CarKeyLayout({required this.pass, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(pass.backgroundColor, const Color(0xFF1E293B));
    final textColor = _getContrastingColor(bgColor);
    final vehicle = _getFieldValue(pass.fields, 'VEHICLE');
    final keyStatus = _getFieldValue(pass.fields, 'KEY STATUS');
    final vin = _getFieldValue(pass.fields, 'VIN');
    final device = _getFieldValue(pass.fields, 'DEVICE');

    return _GoogleWalletBaseLayout(
      pass: pass,
      onTap: onTap,
      titleIcon: Icons.directions_car_rounded,
      fieldRows: [
        _GWSingleRow(label: 'Vehicle', value: vehicle, textColor: textColor),
        _GWTwoItemRow(
          startLabel: 'Key Status', startValue: keyStatus,
          endLabel: 'VIN', endValue: vin,
          textColor: textColor,
        ),
        _GWSingleRow(label: 'Device', value: device, textColor: textColor),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// CAMPUS ID
// -----------------------------------------------------------------------------
class _CampusIdLayout extends StatelessWidget {
  final Pass pass;
  final VoidCallback onTap;
  const _CampusIdLayout({required this.pass, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(pass.backgroundColor, const Color(0xFF1E293B));
    final textColor = _getContrastingColor(bgColor);
    final studentName = _getFieldValue(pass.fields, 'STUDENT NAME');
    final university = _getFieldValue(pass.fields, 'UNIVERSITY');
    final idNumber = _getFieldValue(pass.fields, 'ID #');
    final year = _getFieldValue(pass.fields, 'YEAR');
    final dorm = _getFieldValue(pass.fields, 'DORM');

    return _GoogleWalletBaseLayout(
      pass: pass,
      onTap: onTap,
      titleIcon: Icons.school_rounded,
      fieldRows: [
        _GWSingleRow(label: 'Student Name', value: studentName, textColor: textColor),
        _GWTwoItemRow(
          startLabel: 'University', startValue: university.isNotEmpty ? university : pass.organizationName,
          endLabel: 'ID #', endValue: idNumber,
          textColor: textColor,
        ),
        _GWTwoItemRow(
          startLabel: 'Year', startValue: year,
          endLabel: 'Dorm', endValue: dorm,
          textColor: textColor,
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// CORPORATE BADGE
// -----------------------------------------------------------------------------
class _CorporateBadgeLayout extends StatelessWidget {
  final Pass pass;
  final VoidCallback onTap;
  const _CorporateBadgeLayout({required this.pass, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(pass.backgroundColor, const Color(0xFF1E293B));
    final textColor = _getContrastingColor(bgColor);
    final employeeName = _getFieldValue(pass.fields, 'EMPLOYEE NAME');
    final company = _getFieldValue(pass.fields, 'COMPANY');
    final department = _getFieldValue(pass.fields, 'DEPT');
    final idNumber = _getFieldValue(pass.fields, 'ID #');
    final accessLevel = _getFieldValue(pass.fields, 'ACCESS LEVEL');

    return _GoogleWalletBaseLayout(
      pass: pass,
      onTap: onTap,
      titleIcon: Icons.badge_rounded,
      fieldRows: [
        _GWSingleRow(label: 'Employee Name', value: employeeName, textColor: textColor),
        _GWTwoItemRow(
          startLabel: 'Company', startValue: company.isNotEmpty ? company : pass.organizationName,
          endLabel: 'Department', endValue: department,
          textColor: textColor,
        ),
        _GWTwoItemRow(
          startLabel: 'ID #', startValue: idNumber,
          endLabel: 'Access Level', endValue: accessLevel,
          textColor: textColor,
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// HOTEL KEY
// -----------------------------------------------------------------------------
class _HotelKeyLayout extends StatelessWidget {
  final Pass pass;
  final VoidCallback onTap;
  const _HotelKeyLayout({required this.pass, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(pass.backgroundColor, const Color(0xFF1E293B));
    final textColor = _getContrastingColor(bgColor);
    final guestName = _getFieldValue(pass.fields, 'GUEST NAME');
    final hotel = _getFieldValue(pass.fields, 'HOTEL');
    final roomNumber = _getFieldValue(pass.fields, 'ROOM #');
    final checkIn = _getFieldValue(pass.fields, 'CHECK-IN');
    final checkOut = _getFieldValue(pass.fields, 'CHECK-OUT');

    return _GoogleWalletBaseLayout(
      pass: pass,
      onTap: onTap,
      titleIcon: Icons.hotel_rounded,
      fieldRows: [
        _GWSingleRow(label: 'Guest Name', value: guestName, textColor: textColor),
        _GWTwoItemRow(
          startLabel: 'Hotel', startValue: hotel.isNotEmpty ? hotel : pass.organizationName,
          endLabel: 'Room #', endValue: roomNumber,
          textColor: textColor,
        ),
        _GWTwoItemRow(
          startLabel: 'Check-in', startValue: checkIn,
          endLabel: 'Check-out', endValue: checkOut,
          textColor: textColor,
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// MULTI-FAMILY KEY
// -----------------------------------------------------------------------------
class _MultiFamilyKeyLayout extends StatelessWidget {
  final Pass pass;
  final VoidCallback onTap;
  const _MultiFamilyKeyLayout({required this.pass, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(pass.backgroundColor, const Color(0xFF1E293B));
    final textColor = _getContrastingColor(bgColor);
    final residentName = _getFieldValue(pass.fields, 'RESIDENT NAME');
    final property = _getFieldValue(pass.fields, 'PROPERTY');
    final unitNumber = _getFieldValue(pass.fields, 'UNIT #');
    final accessLevel = _getFieldValue(pass.fields, 'ACCESS LEVEL');

    return _GoogleWalletBaseLayout(
      pass: pass,
      onTap: onTap,
      titleIcon: Icons.apartment_rounded,
      fieldRows: [
        _GWSingleRow(label: 'Resident Name', value: residentName, textColor: textColor),
        _GWTwoItemRow(
          startLabel: 'Property', startValue: property.isNotEmpty ? property : pass.organizationName,
          endLabel: 'Unit #', endValue: unitNumber,
          textColor: textColor,
        ),
        _GWSingleRow(label: 'Access Level', value: accessLevel, textColor: textColor),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// DIGITAL CREDENTIAL
// -----------------------------------------------------------------------------
class _DigitalCredentialLayout extends StatelessWidget {
  final Pass pass;
  final VoidCallback onTap;
  const _DigitalCredentialLayout({required this.pass, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(pass.backgroundColor, const Color(0xFF1E293B));
    final textColor = _getContrastingColor(bgColor);
    final docType = _getFieldValue(pass.fields, 'DOCUMENT TYPE');
    final issuer = _getFieldValue(pass.fields, 'ISSUER');
    final idNumber = _getFieldValue(pass.fields, 'ID #');
    final expiry = _getFieldValue(pass.fields, 'EXPIRY');
    final verified = _getFieldValue(pass.fields, 'VERIFIED');

    return _GoogleWalletBaseLayout(
      pass: pass,
      onTap: onTap,
      titleIcon: Icons.verified_user_rounded,
      fieldRows: [
        _GWSingleRow(label: 'Document Type', value: docType, textColor: textColor),
        _GWTwoItemRow(
          startLabel: 'Issuer', startValue: issuer.isNotEmpty ? issuer : pass.organizationName,
          endLabel: 'ID #', endValue: idNumber,
          textColor: textColor,
        ),
        _GWTwoItemRow(
          startLabel: 'Expiry', startValue: expiry,
          endLabel: 'Verified', endValue: verified,
          textColor: textColor,
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// GENERIC PRIVATE PASS
// -----------------------------------------------------------------------------
class _GenericPrivateLayout extends StatelessWidget {
  final Pass pass;
  final VoidCallback onTap;
  const _GenericPrivateLayout({required this.pass, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(pass.backgroundColor, const Color(0xFF1E293B));
    final textColor = _getContrastingColor(bgColor);
    final dataType = _getFieldValue(pass.fields, 'DATA TYPE');
    final idNumber = _getFieldValue(pass.fields, 'ID #');
    final notes = _getFieldValue(pass.fields, 'NOTES');

    return _GoogleWalletBaseLayout(
      pass: pass,
      onTap: onTap,
      titleIcon: Icons.lock_rounded,
      fieldRows: [
        _GWSingleRow(label: 'Data Type', value: dataType, textColor: textColor),
        _GWSingleRow(label: 'ID #', value: idNumber, textColor: textColor),
        if (notes.isNotEmpty)
          _GWSingleRow(label: 'Notes', value: notes, textColor: textColor),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// IN-STORE PAYMENT
// -----------------------------------------------------------------------------
class _InStorePaymentLayout extends StatelessWidget {
  final Pass pass;
  final VoidCallback onTap;
  const _InStorePaymentLayout({required this.pass, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(pass.backgroundColor, const Color(0xFF1E293B));
    final textColor = _getContrastingColor(bgColor);
    final cardNumber = _getFieldValue(pass.fields, 'CARD NUMBER');
    final memberName = _getFieldValue(pass.fields, 'MEMBER NAME');
    final cardType = _getFieldValue(pass.fields, 'CARD TYPE');

    return _GoogleWalletBaseLayout(
      pass: pass,
      onTap: onTap,
      titleIcon: Icons.contactless_rounded,
      fieldRows: [
        _GWSingleRow(label: 'Card Number', value: cardNumber, textColor: textColor),
        _GWTwoItemRow(
          startLabel: 'Member Name', startValue: memberName,
          endLabel: 'Card Type', endValue: cardType,
          textColor: textColor,
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// COUPON (Legacy)
// -----------------------------------------------------------------------------
class _CouponLayout extends StatelessWidget {
  final Pass pass;
  final VoidCallback onTap;
  const _CouponLayout({required this.pass, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(pass.backgroundColor, const Color(0xFF1E293B));
    final textColor = _getContrastingColor(bgColor);
    final offer = _getFieldValue(pass.fields, 'OFFER');
    final expires = _getFieldValue(pass.fields, 'EXPIRES');
    final merchant = _getFieldValue(pass.fields, 'MERCHANT');
    final terms = _getFieldValue(pass.fields, 'TERMS');

    return _GoogleWalletBaseLayout(
      pass: pass,
      onTap: onTap,
      titleIcon: Icons.local_offer_rounded,
      fieldRows: [
        if (offer.isNotEmpty)
          _GWSingleRow(label: 'Offer', value: offer, textColor: textColor),
        _GWTwoItemRow(
          startLabel: 'Merchant', startValue: merchant,
          endLabel: 'Expires', endValue: expires,
          textColor: textColor,
        ),
        if (terms.isNotEmpty)
          _GWSingleRow(label: 'Terms', value: terms, textColor: textColor),
      ],
    );
  }
}
