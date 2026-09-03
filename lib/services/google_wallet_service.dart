import 'dart:convert';
import 'package:wallet/models/pass.dart';
import 'package:wallet/services/barcode_utils.dart';

class GoogleWalletService {
  static final GoogleWalletService instance = GoogleWalletService._();
  GoogleWalletService._();

  bool isGoogleWalletUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.contains('pay.google.com/gp/v/save') ||
        trimmed.contains('wallet.google.com') ||
        (trimmed.startsWith('eyJ') && trimmed.contains('.'))) {
      return true;
    }
    return false;
  }

  Map<String, dynamic>? extractJwtPayload(String input) {
    try {
      String token = input.trim();
      if (token.contains('/save/')) {
        token = token.substring(token.indexOf('/save/') + 6);
      } else if (token.contains('save=')) {
        final uri = Uri.tryParse(token);
        final param = uri?.queryParameters['save'];
        if (param != null) token = param;
      }

      if (token.contains('?')) {
        token = token.substring(0, token.indexOf('?'));
      }
      if (token.contains('#')) {
        token = token.substring(0, token.indexOf('#'));
      }

      final parts = token.split('.');
      if (parts.length < 2) return null;

      String payloadB64 = parts[1];
      String normalized = base64Url.normalize(payloadB64);
      final decodedJsonStr = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decodedJsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Pass? parseGoogleWalletUrl(String input) {
    try {
      final jwtPayload = extractJwtPayload(input);
      if (jwtPayload == null) return null;

      Map<String, dynamic> data = jwtPayload;
      if (data.containsKey('payload') && data['payload'] is Map<String, dynamic>) {
        data = data['payload'] as Map<String, dynamic>;
      }

      if (data.containsKey('flightObjects') && (data['flightObjects'] as List).isNotEmpty) {
        return _parseFlightPass(data['flightObjects'][0] as Map<String, dynamic>, data);
      }
      if (data.containsKey('eventTicketObjects') && (data['eventTicketObjects'] as List).isNotEmpty) {
        return _parseEventTicketPass(data['eventTicketObjects'][0] as Map<String, dynamic>, data);
      }
      if (data.containsKey('transitObjects') && (data['transitObjects'] as List).isNotEmpty) {
        return _parseTransitPass(data['transitObjects'][0] as Map<String, dynamic>, data);
      }
      if (data.containsKey('loyaltyObjects') && (data['loyaltyObjects'] as List).isNotEmpty) {
        return _parseLoyaltyPass(data['loyaltyObjects'][0] as Map<String, dynamic>, data);
      }
      if (data.containsKey('giftCardObjects') && (data['giftCardObjects'] as List).isNotEmpty) {
        return _parseGiftCardPass(data['giftCardObjects'][0] as Map<String, dynamic>, data);
      }
      if (data.containsKey('offerObjects') && (data['offerObjects'] as List).isNotEmpty) {
        return _parseOfferPass(data['offerObjects'][0] as Map<String, dynamic>, data);
      }
      if (data.containsKey('genericObjects') && (data['genericObjects'] as List).isNotEmpty) {
        return _parseGenericPass(data['genericObjects'][0] as Map<String, dynamic>, data);
      }

      return _parseGenericPass(data, data);
    } catch (_) {
      return null;
    }
  }

  String _extractValue(dynamic node) {
    if (node == null) return '';
    if (node is String) return node;
    if (node is Map) {
      if (node.containsKey('defaultValue') && node['defaultValue'] is Map) {
        return _extractValue(node['defaultValue']['value']);
      }
      if (node.containsKey('value')) return _extractValue(node['value']);
    }
    return node.toString();
  }

  Map<String, String?> _extractBarcode(Map<String, dynamic> obj) {
    String? val;
    String? fmt;
    String? alt;

    if (obj.containsKey('barcode') && obj['barcode'] is Map) {
      final bc = obj['barcode'] as Map;
      val = bc['value']?.toString();
      alt = bc['alternateText']?.toString();
      final t = bc['type']?.toString().toUpperCase();
      if (t != null) {
        if (t.contains('QR')) {
          fmt = 'QR Code';
        } else if (t.contains('128')) {
          fmt = 'Code 128';
        } else if (t.contains('39')) {
          fmt = 'Code 39';
        } else if (t.contains('PDF')) {
          fmt = 'PDF417';
        } else if (t.contains('AZTEC')) {
          fmt = 'Aztec';
        } else if (t.contains('EAN')) {
          fmt = 'EAN-13';
        } else if (t.contains('UPC')) {
          fmt = 'UPC-A';
        }
      }
    }
    return {'value': val, 'format': fmt ?? 'QR Code', 'alt': alt};
  }

  String? _extractColor(Map<String, dynamic> obj, Map<String, dynamic> root) {
    if (obj.containsKey('hexBackgroundColor')) return obj['hexBackgroundColor']?.toString();
    if (root.containsKey('hexBackgroundColor')) return root['hexBackgroundColor']?.toString();
    return null;
  }

  Pass _parseFlightPass(Map<String, dynamic> obj, Map<String, dynamic> root) {
    final bc = _extractBarcode(obj);
    final passenger = _extractValue(obj['passengerName']);
    final reservation = _extractValue(obj['reservationInfo']?['confirmationCode']);
    
    final flightHeader = obj['flightHeader'] as Map<String, dynamic>?;
    final carrier = _extractValue(flightHeader?['carrier']?['carrierIataCode'] ?? flightHeader?['carrier']?['carrierName']);
    final flightNum = _extractValue(flightHeader?['flightNumber']);
    
    final origin = _extractValue(obj['origin']?['airportIataCode'] ?? obj['origin']?['airportName']);
    final dest = _extractValue(obj['destination']?['airportIataCode'] ?? obj['destination']?['airportName']);
    
    final seat = _extractValue(obj['boardingAndSeatingPolicy']?['seatNumber'] ?? obj['seat']);
    final gate = _extractValue(obj['boardingAndSeatingPolicy']?['gateNumber'] ?? obj['gate']);
    final boardingTime = _extractValue(obj['boardingAndSeatingPolicy']?['boardingTime'] ?? obj['boardingTime']);

    final orgName = carrier.isNotEmpty ? carrier : (obj['issuerName']?.toString() ?? 'Airline');

    return Pass(
      type: 'boardingPass',
      organizationName: orgName,
      logoText: '$carrier $flightNum'.trim(),
      barcodeValue: bc['value'] ?? reservation,
      barcodeFormat: BarcodeUtils.getInternalFormatName(bc['format']!),
      barcodeAltText: bc['alt'] ?? seat,
      relevantDate: boardingTime.isNotEmpty ? boardingTime : null,
      backgroundColor: _extractColor(obj, root) ?? 'navy',
      fields: {
        'primaryFields': [
          {'label': 'FROM', 'value': origin},
          {'label': 'TO', 'value': dest},
        ],
        'secondaryFields': [
          {'label': 'PASSENGER', 'value': passenger},
          {'label': 'FLIGHT', 'value': flightNum},
        ],
        'auxiliaryFields': [
          {'label': 'GATE', 'value': gate},
          {'label': 'SEAT', 'value': seat},
          {'label': 'BOARDING', 'value': boardingTime},
        ],
      },
    );
  }

  Pass _parseEventTicketPass(Map<String, dynamic> obj, Map<String, dynamic> root) {
    final bc = _extractBarcode(obj);
    final eventName = _extractValue(obj['eventName']);
    final venue = _extractValue(obj['venue']?['name']);
    final dateTime = _extractValue(obj['dateTime']?['start'] ?? obj['dateTime']);
    final section = _extractValue(obj['seatInfo']?['section']);
    final row = _extractValue(obj['seatInfo']?['row']);
    final seat = _extractValue(obj['seatInfo']?['seat']);

    final orgName = _extractValue(obj['issuerName']).isNotEmpty
        ? _extractValue(obj['issuerName'])
        : (venue.isNotEmpty ? venue : 'Event Ticket');

    return Pass(
      type: 'eventTicket',
      organizationName: orgName,
      logoText: eventName.isNotEmpty ? eventName : 'Event',
      barcodeValue: bc['value'] ?? '',
      barcodeFormat: BarcodeUtils.getInternalFormatName(bc['format']!),
      barcodeAltText: bc['alt'],
      relevantDate: dateTime.isNotEmpty ? dateTime : null,
      backgroundColor: _extractColor(obj, root) ?? 'obsidian',
      fields: {
        'primaryFields': [
          {'label': 'EVENT', 'value': eventName},
        ],
        'secondaryFields': [
          {'label': 'VENUE', 'value': venue},
          {'label': 'DATE', 'value': dateTime},
        ],
        'auxiliaryFields': [
          {'label': 'SECTION', 'value': section},
          {'label': 'ROW', 'value': row},
          {'label': 'SEAT', 'value': seat},
        ],
      },
    );
  }

  Pass _parseTransitPass(Map<String, dynamic> obj, Map<String, dynamic> root) {
    final bc = _extractBarcode(obj);
    final agency = _extractValue(obj['transitAgencyName'] ?? obj['issuerName']);
    final ticketLeg = obj['ticketLeg'] as Map<String, dynamic>?;
    final origin = _extractValue(ticketLeg?['originStationName']);
    final dest = _extractValue(ticketLeg?['destinationStationName']);
    final depTime = _extractValue(ticketLeg?['departureDateTime']);
    final passenger = _extractValue(obj['passengerName']);

    return Pass(
      type: 'transitPass',
      organizationName: agency.isNotEmpty ? agency : 'Transit',
      logoText: agency,
      barcodeValue: bc['value'] ?? '',
      barcodeFormat: BarcodeUtils.getInternalFormatName(bc['format']!),
      barcodeAltText: bc['alt'],
      relevantDate: depTime.isNotEmpty ? depTime : null,
      backgroundColor: _extractColor(obj, root) ?? 'emerald',
      fields: {
        'primaryFields': [
          {'label': 'FROM', 'value': origin},
          {'label': 'TO', 'value': dest},
        ],
        'secondaryFields': [
          {'label': 'PASSENGER', 'value': passenger},
          {'label': 'DEPARTURE', 'value': depTime},
        ],
      },
    );
  }

  Pass _parseLoyaltyPass(Map<String, dynamic> obj, Map<String, dynamic> root) {
    final bc = _extractBarcode(obj);
    final program = _extractValue(obj['programName'] ?? obj['issuerName']);
    final accountName = _extractValue(obj['accountName']);
    final accountId = _extractValue(obj['accountId']);
    final points = _extractValue(obj['loyaltyPoints']?['points'] ?? obj['points']);

    return Pass(
      type: 'loyaltyCard',
      organizationName: program.isNotEmpty ? program : 'Loyalty Card',
      logoText: program,
      barcodeValue: bc['value'] ?? accountId,
      barcodeFormat: BarcodeUtils.getInternalFormatName(bc['format']!),
      barcodeAltText: bc['alt'] ?? accountId,
      backgroundColor: _extractColor(obj, root) ?? 'amethyst',
      fields: {
        'primaryFields': [
          {'label': 'MEMBER', 'value': accountName},
        ],
        'secondaryFields': [
          {'label': 'ACCOUNT #', 'value': accountId},
          {'label': 'POINTS', 'value': points},
        ],
      },
    );
  }

  Pass _parseGiftCardPass(Map<String, dynamic> obj, Map<String, dynamic> root) {
    final bc = _extractBarcode(obj);
    final issuer = _extractValue(obj['issuerName'] ?? obj['merchantName']);
    final cardNum = _extractValue(obj['cardNumber']);
    final pin = _extractValue(obj['pin']);
    final balance = _extractValue(obj['balance']?['micros'] != null
        ? '${(obj['balance']['micros'] as num) / 1000000} ${obj['balance']['currencyCode'] ?? ''}'
        : obj['balance']);

    return Pass(
      type: 'giftCard',
      organizationName: issuer.isNotEmpty ? issuer : 'Gift Card',
      logoText: issuer,
      barcodeValue: bc['value'] ?? cardNum,
      barcodeFormat: BarcodeUtils.getInternalFormatName(bc['format']!),
      barcodeAltText: bc['alt'] ?? cardNum,
      backgroundColor: _extractColor(obj, root) ?? 'crimson',
      fields: {
        'primaryFields': [
          {'label': 'CARD NUMBER', 'value': cardNum},
        ],
        'secondaryFields': [
          {'label': 'BALANCE', 'value': balance},
          {'label': 'PIN', 'value': pin},
        ],
      },
    );
  }

  Pass _parseOfferPass(Map<String, dynamic> obj, Map<String, dynamic> root) {
    final bc = _extractBarcode(obj);
    final title = _extractValue(obj['title'] ?? obj['shortTitle']);
    final provider = _extractValue(obj['provider'] ?? obj['issuerName']);
    final redemptionCode = _extractValue(obj['redemptionCode']);
    final validTime = _extractValue(obj['validTimeInterval']?['end']?['date']);

    return Pass(
      type: 'offer',
      organizationName: provider.isNotEmpty ? provider : 'Offer',
      logoText: title,
      barcodeValue: bc['value'] ?? redemptionCode,
      barcodeFormat: BarcodeUtils.getInternalFormatName(bc['format']!),
      barcodeAltText: bc['alt'] ?? redemptionCode,
      relevantDate: validTime.isNotEmpty ? validTime : null,
      backgroundColor: _extractColor(obj, root) ?? 'sunset',
      fields: {
        'primaryFields': [
          {'label': 'OFFER', 'value': title},
        ],
        'secondaryFields': [
          {'label': 'CODE', 'value': redemptionCode},
          {'label': 'EXPIRES', 'value': validTime},
        ],
      },
    );
  }

  Pass _parseGenericPass(Map<String, dynamic> obj, Map<String, dynamic> root) {
    final bc = _extractBarcode(obj);
    final header = _extractValue(obj['header'] ?? obj['cardTitle']);
    final subheader = _extractValue(obj['subheader']);
    final issuer = _extractValue(obj['issuerName'] ?? obj['cardTitle'] ?? 'Pass');

    final primaryList = <Map<String, dynamic>>[];
    if (header.isNotEmpty) primaryList.add({'label': 'TITLE', 'value': header});
    if (subheader.isNotEmpty) primaryList.add({'label': 'INFO', 'value': subheader});

    final auxList = <Map<String, dynamic>>[];
    if (obj['textModulesData'] is List) {
      for (var mod in obj['textModulesData']) {
        if (mod is Map) {
          final h = _extractValue(mod['header']);
          final b = _extractValue(mod['body']);
          if (h.isNotEmpty && b.isNotEmpty) {
            auxList.add({'label': h.toUpperCase(), 'value': b});
          }
        }
      }
    }

    return Pass(
      type: 'generic',
      organizationName: issuer.isNotEmpty ? issuer : 'Digital Pass',
      logoText: header.isNotEmpty ? header : issuer,
      barcodeValue: bc['value'] ?? '',
      barcodeFormat: BarcodeUtils.getInternalFormatName(bc['format']!),
      barcodeAltText: bc['alt'],
      backgroundColor: _extractColor(obj, root) ?? 'obsidian',
      fields: {
        if (primaryList.isNotEmpty) 'primaryFields': primaryList,
        if (auxList.isNotEmpty) 'auxiliaryFields': auxList,
      },
    );
  }
}
