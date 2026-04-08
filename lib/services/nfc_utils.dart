import 'package:nfc_manager/nfc_manager.dart';

/// NFC utility functions for the wallet app
class NfcUtils {
  /// Check if NFC is available on this device
  static Future<bool> isNfcAvailable() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (e) {
      return false;
    }
  }

  /// Check if NFC is enabled on the device
  static Future<bool> isNfcEnabled() async {
    try {
      // NFC is enabled if we can read a tag
      // We can't directly check if NFC is enabled, but we can try to read
      final isEnabled = await NfcManager.instance.isAvailable();
      return isEnabled;
    } catch (e) {
      return false;
    }
  }

  /// Get a user-friendly message for NFC errors
  static String getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('not available')) {
      return 'NFC is not available on this device';
    } else if (errorString.contains('not enabled')) {
      return 'Please enable NFC in your device settings';
    } else if (errorString.contains('permission')) {
      return 'NFC permission denied. Please grant permission in settings';
    } else if (errorString.contains('timeout')) {
      return 'NFC scan timed out. Please try again';
    } else if (errorString.contains('cancelled')) {
      return 'NFC scan was cancelled';
    } else if (errorString.contains('session')) {
      return 'NFC session error. Please try again';
    }

    return 'NFC error: ${error.toString()}';
  }

  /// Get status message for NFC scanning
  static String getStatusMessage(bool isAvailable) {
    if (isAvailable) {
      return 'NFC is ready';
    } else {
      return 'NFC is not available';
    }
  }

  /// Format card number for display (with spaces every 4 digits)
  static String formatCardNumber(String number) {
    final cleaned = number.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    for (int i = 0; i < cleaned.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(cleaned[i]);
    }

    return buffer.toString();
  }

  /// Format expiry date from MMYY to MM/YY
  static String formatExpiryDate(String expiry) {
    final cleaned = expiry.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length >= 4) {
      return '${cleaned.substring(0, 2)}/${cleaned.substring(2, 4)}';
    }
    return expiry;
  }

  /// Detect card network from partial data
  static String? detectCardNetwork(String? cardNumber) {
    if (cardNumber == null) return null;

    final cleaned = cardNumber.replaceAll(RegExp(r'\D'), '');

    if (cleaned.startsWith('4')) {
      return 'visa';
    } else if (cleaned.startsWith('5') || cleaned.startsWith('2')) {
      return 'mastercard';
    } else if (cleaned.startsWith('3')) {
      return 'amex';
    } else if (cleaned.startsWith('6')) {
      return 'discover';
    } else if (cleaned.startsWith('60') || cleaned.startsWith('65')) {
      return 'rupay';
    }

    return null;
  }

  /// Validate if a string looks like a valid card number (Luhn algorithm)
  static bool isValidCardNumber(String? number) {
    if (number == null) return false;

    final cleaned = number.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length < 13 || cleaned.length > 19) return false;

    int sum = 0;
    bool alternate = false;

    for (int i = cleaned.length - 1; i >= 0; i--) {
      int n = int.parse(cleaned[i]);

      if (alternate) {
        n *= 2;
        if (n > 9) {
          n -= 9;
        }
      }

      sum += n;
      alternate = !alternate;
    }

    return (sum % 10 == 0);
  }

  /// Validate expiry date
  static bool isValidExpiryDate(String? expiry) {
    if (expiry == null) return false;

    final cleaned = expiry.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length != 4) return false;

    final month = int.tryParse(cleaned.substring(0, 2));
    final year = int.tryParse(cleaned.substring(2, 4));

    if (month == null || year == null) return false;
    if (month < 1 || month > 12) return false;

    // Check if not expired
    final now = DateTime.now();
    final currentYear = now.year % 100;
    final currentMonth = now.month;

    if (year < currentYear) return false;
    if (year == currentYear && month < currentMonth) return false;

    return true;
  }
}

/// Enum for NFC status
enum NfcStatus { available, unavailable, disabled }
