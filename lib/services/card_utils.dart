/// Card utility functions for the wallet app
/// Handles card number validation, formatting, and network detection
class CardUtils {
  /// Detect card network from card number using IIN/BIN ranges
  /// Based on ISO/IEC 7812 standards
  static String? detectCardNetwork(String? cardNumber) {
    if (cardNumber == null) return null;

    final cleaned = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (cleaned.isEmpty) return null;

    // American Express: starts with 34 or 37
    if (cleaned.length >= 2) {
      final prefix2 = int.tryParse(cleaned.substring(0, 2)) ?? 0;
      if (prefix2 == 34 || prefix2 == 37) {
        return 'amex';
      }
    }

    // RuPay: starts with 60, 65, 81, 82, or 508
    // Must check before Discover since both can start with 60/65
    if (cleaned.length >= 2) {
      final prefix2 = int.tryParse(cleaned.substring(0, 2)) ?? 0;
      if (prefix2 == 81 || prefix2 == 82) {
        return 'rupay';
      }
      if (prefix2 == 50) {
        if (cleaned.length >= 3 && cleaned[2] == '8') {
          return 'rupay';
        }
      }
    }

    // Discover: starts with 6011, 644-649, or 65
    if (cleaned.length >= 2) {
      final prefix2 = int.tryParse(cleaned.substring(0, 2)) ?? 0;
      if (prefix2 >= 64 && prefix2 <= 69) {
        return 'discover';
      }
      if (prefix2 == 65) {
        return 'discover';
      }
    }
    if (cleaned.length >= 4) {
      final prefix4 = int.tryParse(cleaned.substring(0, 4)) ?? 0;
      if (prefix4 == 6011) {
        return 'discover';
      }
    }

    // Mastercard: starts with 51-55 or 2221-2720
    if (cleaned.length >= 2) {
      final prefix2 = int.tryParse(cleaned.substring(0, 2)) ?? 0;
      if (prefix2 >= 51 && prefix2 <= 55) {
        return 'mastercard';
      }
    }
    if (cleaned.length >= 4) {
      final prefix4 = int.tryParse(cleaned.substring(0, 4)) ?? 0;
      if (prefix4 >= 2221 && prefix4 <= 2720) {
        return 'mastercard';
      }
    }

    // Visa: starts with 4
    if (cleaned.startsWith('4')) {
      return 'visa';
    }

    return null;
  }

  /// Get valid card number lengths for a given network
  static List<int> getValidLengthsForNetwork(String network) {
    switch (network) {
      case 'visa':
        return [13, 16, 19];
      case 'mastercard':
        return [16];
      case 'amex':
        return [15];
      case 'discover':
        return [16, 17, 18, 19];
      case 'rupay':
        return [16];
      default:
        return [14, 15, 16]; // fallback for unknown networks
    }
  }

  /// Validate card number length based on detected network
  static bool isValidLengthForNetwork(String cardNumber, String network) {
    final cleaned = cardNumber.replaceAll(RegExp(r'\D'), '');
    final validLengths = getValidLengthsForNetwork(network);
    return validLengths.contains(cleaned.length);
  }

  /// Get user-friendly error message for invalid card length
  static String getLengthErrorMessage(String network) {
    final validLengths = getValidLengthsForNetwork(network);
    if (validLengths.length == 1) {
      return '${network.toUpperCase()} cards must be ${validLengths.first} digits';
    } else if (validLengths.length == 2) {
      return '${network.toUpperCase()} cards must be ${validLengths.join(' or ')} digits';
    } else {
      final min = validLengths.reduce((a, b) => a < b ? a : b);
      final max = validLengths.reduce((a, b) => a > b ? a : b);
      return '${network.toUpperCase()} cards must be $min-$max digits';
    }
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
