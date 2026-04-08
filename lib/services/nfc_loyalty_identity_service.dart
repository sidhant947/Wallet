import 'dart:async';
import 'package:nfc_manager/nfc_manager.dart';

/// Represents data extracted from a loyalty/identity card via NFC
class NfcLoyaltyIdentityData {
  final String? cardName;
  final String? cardNumber;
  final String? additionalData;
  final Map<String, String>? customFields;

  NfcLoyaltyIdentityData({
    this.cardName,
    this.cardNumber,
    this.additionalData,
    this.customFields,
  });

  bool get hasData => cardName != null || cardNumber != null;

  Map<String, String?> toMap() {
    return {
      'cardName': cardName,
      'cardNumber': cardNumber,
      'additionalData': additionalData,
      'customFields': customFields?.toString(),
    };
  }
}

/// Service for reading loyalty and identity cards via NFC (100% offline)
class NfcLoyaltyIdentityService {
  static final NfcLoyaltyIdentityService _instance =
      NfcLoyaltyIdentityService._internal();
  factory NfcLoyaltyIdentityService() => _instance;
  NfcLoyaltyIdentityService._internal();

  /// Check if NFC is available on this device
  Future<bool> isNfcAvailable() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (e) {
      return false;
    }
  }

  /// Start NFC session and read loyalty/identity card data
  /// Returns NfcLoyaltyIdentityData with extracted information
  Future<NfcLoyaltyIdentityData> readCardData({
    void Function(String status)? onStatus,
  }) async {
    try {
      onStatus?.call('Starting NFC session...');

      // Check NFC availability
      final isAvailable = await isNfcAvailable();
      if (!isAvailable) {
        throw Exception('NFC is not available on this device');
      }

      onStatus?.call('Ready to scan. Hold card/tag near device...');

      // Start NFC session with timeout
      final completer = Completer<NfcLoyaltyIdentityData>();

      await NfcManager.instance.startSession(
        onError: (error) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
          return Future.value();
        },
        onDiscovered: (NfcTag tag) async {
          try {
            onStatus?.call('Tag detected! Reading data...');

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
        onStatus?.call('No readable data found on card/tag');
      }

      return result;
    } catch (e) {
      onStatus?.call('Error: ${e.toString()}');
      NfcManager.instance.stopSession(errorMessage: 'Scan failed');
      rethrow;
    }
  }

  /// Parse NFC tag data from loyalty/identity card
  Future<NfcLoyaltyIdentityData> _parseNfcTag(NfcTag tag) async {
    try {
      // Try NDEF first (most common for loyalty/identity cards)
      final ndef = Ndef.from(tag);
      if (ndef != null) {
        return await _readNdefCard(ndef);
      }
    } catch (e) {
      // NDEF reading failed
    }

    // No readable data
    return NfcLoyaltyIdentityData();
  }

  /// Read NDEF format card (most common)
  Future<NfcLoyaltyIdentityData> _readNdefCard(Ndef ndef) async {
    try {
      final ndefMessage = await ndef.read();

      String? cardName;
      String? cardNumber;
      final additionalDataList = <String>[];

      for (final record in ndefMessage.records) {
        final payload = record.payload;
        // For text records, skip the first byte (language code length)
        final text = payload.length > 1
            ? String.fromCharCodes(payload.sublist(1)).trim()
            : '';

        if (text.isEmpty) continue;

        // Look for card/loyalty number (numeric sequence, at least 4 digits)
        final numberMatch = RegExp(r'\d{4,}').firstMatch(text);
        if (numberMatch != null && cardNumber == null) {
          cardNumber = numberMatch.group(0);
          continue;
        }

        // If it's not just numbers and we don't have a name yet, treat it as name
        if (cardName == null &&
            text.length > 2 &&
            !RegExp(r'^\d+$').hasMatch(text)) {
          cardName = text;
          continue;
        }

        // Store any other data
        if (text.isNotEmpty) {
          additionalDataList.add(text);
        }
      }

      return NfcLoyaltyIdentityData(
        cardName: cardName,
        cardNumber: cardNumber,
        additionalData: additionalDataList.isNotEmpty
            ? additionalDataList.join('\n')
            : null,
      );
    } catch (e) {
      return NfcLoyaltyIdentityData();
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
