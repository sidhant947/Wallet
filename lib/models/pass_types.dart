import 'package:flutter/material.dart';

enum PassCategory {
  retail('Retail'),
  tickets('Tickets & Transit'),
  access('Access'),
  health('Health'),
  identity('Identity'),
  generic('Generic');

  final String label;
  const PassCategory(this.label);
}

enum PassType {
  // Retail
  loyaltyCard('loyaltyCard', PassCategory.retail, 'Loyalty Card', Icons.card_membership_rounded),
  giftCard('giftCard', PassCategory.retail, 'Gift Card', Icons.card_giftcard_rounded),
  offer('offer', PassCategory.retail, 'Offer', Icons.local_offer_rounded),
  inStorePayment('inStorePayment', PassCategory.retail, 'In-Store Payment', Icons.contactless_rounded),

  // Tickets & Transit
  boardingPass('boardingPass', PassCategory.tickets, 'Boarding Pass', Icons.flight_rounded),
  eventTicket('eventTicket', PassCategory.tickets, 'Event Ticket', Icons.confirmation_number_rounded),
  transitPass('transitPass', PassCategory.tickets, 'Transit Pass', Icons.directions_bus_rounded),

  // Access
  digitalCarKey('digitalCarKey', PassCategory.access, 'Digital Car Key', Icons.directions_car_rounded),
  campusId('campusId', PassCategory.access, 'Campus ID', Icons.school_rounded),
  corporateBadge('corporateBadge', PassCategory.access, 'Corporate Badge', Icons.badge_rounded),
  hotelKey('hotelKey', PassCategory.access, 'Hotel Key', Icons.hotel_rounded),
  multiFamilyKey('multiFamilyKey', PassCategory.access, 'Multi-Family Key', Icons.apartment_rounded),

  // Health
  healthInsuranceCard('healthInsuranceCard', PassCategory.health, 'Health Insurance', Icons.health_and_safety_rounded),
  healthTestRecord('healthTestRecord', PassCategory.health, 'Test Record', Icons.science_rounded),
  healthVaccineCard('healthVaccineCard', PassCategory.health, 'Vaccine Card', Icons.vaccines_rounded),

  // Identity
  digitalCredential('digitalCredential', PassCategory.identity, 'Digital Credential', Icons.verified_user_rounded),

  // Generic
  generic('generic', PassCategory.generic, 'Generic', Icons.credit_card_rounded),
  genericPrivate('genericPrivate', PassCategory.generic, 'Private Pass', Icons.lock_rounded),

  // Legacy (kept for backward compatibility)
  coupon('coupon', PassCategory.retail, 'Coupon', Icons.local_offer_rounded),
  storeCard('storeCard', PassCategory.retail, 'Store Card', Icons.store_rounded);

  final String value;
  final PassCategory category;
  final String label;
  final IconData icon;
  const PassType(this.value, this.category, this.label, this.icon);

  static PassType fromValue(String? value) {
    if (value == null) return PassType.generic;
    for (final type in PassType.values) {
      if (type.value == value) return type;
    }
    return PassType.generic;
  }

  static List<PassType> getByCategory(PassCategory category) {
    return PassType.values.where((t) => t.category == category && !_isLegacy(t)).toList();
  }

  static bool _isLegacy(PassType type) =>
      type == PassType.coupon || type == PassType.storeCard;

  static List<PassType> get allDisplayTypes =>
      PassType.values.where((t) => !_isLegacy(t)).toList();
}

/// Returns the icon for a given pass type string.
IconData getIconForPassType(String type) {
  return PassType.fromValue(type).icon;
}

/// Returns the display label for a given pass type string.
String getPassTypeLabel(String type) {
  return PassType.fromValue(type).label;
}

/// Returns the category for a given pass type string.
PassCategory getPassCategory(String type) {
  return PassType.fromValue(type).category;
}
