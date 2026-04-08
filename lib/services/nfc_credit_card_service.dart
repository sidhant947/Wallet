import 'dart:async';
import 'package:nfc_manager/nfc_manager.dart';

/// Represents data extracted from a credit/debit card via NFC
class NfcCardData {
  final String? cardNumber;
  final String? expiryDate;
  final String? cardholderName;
  final String? network; // Visa, Mastercard, etc.

  NfcCardData({
    this.cardNumber,
    this.expiryDate,
    this.cardholderName,
    this.network,
  });

  bool get hasData =>
      cardNumber != null || expiryDate != null || cardholderName != null;

  Map<String, String?> toMap() {
    return {
      'cardNumber': cardNumber,
      'expiryDate': expiryDate,
      'cardholderName': cardholderName,
      'network': network,
    };
  }
}

/// Service for reading credit/debit cards via NFC (100% offline)
class NfcCreditCardService {
  static final NfcCreditCardService _instance =
      NfcCreditCardService._internal();
  factory NfcCreditCardService() => _instance;
  NfcCreditCardService._internal();

  /// Check if NFC is available on this device
  Future<bool> isNfcAvailable() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (e) {
      return false;
    }
  }

  /// Start NFC session and read credit/debit card data
  /// Returns NfcCardData with extracted information
  Future<NfcCardData> readCardData({
    void Function(String status)? onStatus,
  }) async {
    try {
      onStatus?.call('Starting NFC session...');

      // Check NFC availability
      final isAvailable = await isNfcAvailable();
      if (!isAvailable) {
        throw Exception('NFC is not available on this device');
      }

      onStatus?.call('Ready to scan. Hold card near device...');

      // Start NFC session with timeout
      final completer = Completer<NfcCardData>();

      await NfcManager.instance.startSession(
        onError: (error) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
          return Future.value();
        },
        onDiscovered: (NfcTag tag) async {
          try {
            onStatus?.call('Card detected! Reading data...');

            final cardData = await _parseNfcTag(tag);

            if (!completer.isCompleted) {
              completer.complete(cardData);
            }
          } catch (e) {
            if (!completer.isCompleted) {
              completer.completeError(e);
            }
          }
        },
      );

      // Set timeout for the session (30 seconds)
      await Future.delayed(const Duration(seconds: 30));

      if (!completer.isCompleted) {
        NfcManager.instance.stopSession();
        throw TimeoutException('NFC scan timed out');
      }

      final result = await completer.future;
      NfcManager.instance.stopSession();

      if (result.hasData) {
        onStatus?.call('Successfully read card data!');
      } else {
        onStatus?.call('No readable data found on card');
      }

      return result;
    } catch (e) {
      onStatus?.call('Error: ${e.toString()}');
      NfcManager.instance.stopSession(errorMessage: 'Scan failed');
      rethrow;
    }
  }

  /// Parse NFC tag data from credit/debit card
  Future<NfcCardData> _parseNfcTag(NfcTag tag) async {
    try {
      // Try to read NDEF data
      final ndef = Ndef.from(tag);
      if (ndef != null) {
        return await _readNdefCard(ndef);
      }
    } catch (e) {
      // NDEF reading failed
    }

    // No readable data
    return NfcCardData();
  }

  /// Read NDEF format card
  Future<NfcCardData> _readNdefCard(Ndef ndef) async {
    try {
      final ndefMessage = await ndef.read();

      String? cardNumber;
      String? expiryDate;
      String? cardholderName;

      for (final record in ndefMessage.records) {
        final payload = record.payload;
        // Skip first byte (language code length for text records)
        final text = payload.length > 1
            ? String.fromCharCodes(payload.sublist(1))
            : '';

        // Try to extract card number (13-19 digits)
        final cardNumberMatch = RegExp(r'\d{13,19}').firstMatch(text);
        if (cardNumberMatch != null) {
          cardNumber = cardNumberMatch.group(0);
        }

        // Try to extract expiry date (MM/YY or MMYY format)
        final expiryMatch = RegExp(r'(\d{2})/(\d{2})').firstMatch(text);
        if (expiryMatch != null) {
          expiryDate = expiryMatch.group(0)?.replaceAll('/', '');
        }

        // If no specific patterns matched, treat as cardholder name
        if (cardholderName == null &&
            text.length > 2 &&
            !RegExp(r'^\d+$').hasMatch(text)) {
          cardholderName = text;
        }
      }

      return NfcCardData(
        cardNumber: cardNumber,
        expiryDate: expiryDate,
        cardholderName: cardholderName,
      );
    } catch (e) {
      return NfcCardData();
    }
  }

  /// Stop any active NFC session
  void stopSession() {
    try {
      NfcManager.instance.stopSession();
    } catch (e) {
      // Ignore errors when stopping
    }
  }
}
