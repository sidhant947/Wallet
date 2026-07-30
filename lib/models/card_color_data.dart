import 'package:flutter/material.dart';

class CardColorData {
  final Color primary;
  final Color secondary;
  final Color accent;
  final String name;

  const CardColorData({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.name,
  });

  factory CardColorData.fromHexOrKey(String colorValue, {bool isDark = true}) {
    String cleanHex = colorValue.trim();
    if (cleanHex.startsWith('#')) {
      cleanHex = cleanHex.substring(1);
    }

    if (cleanHex.length == 6) {
      final intValue = int.tryParse(cleanHex, radix: 16);
      if (intValue != null) {
        final Color baseColor = Color(0xFF000000 | intValue);
        final HSLColor hsl = HSLColor.fromColor(baseColor);
        final Color primary = baseColor;
        final Color secondary = hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor();
        final Color accent = hsl.withLightness((hsl.lightness + 0.1).clamp(0.0, 1.0)).toColor();
        return CardColorData(
          primary: primary,
          secondary: secondary,
          accent: accent,
          name: '#${cleanHex.toUpperCase()}',
        );
      }
    }

    final Color fallbackColor = isDark ? const Color(0xFF0F0F0F) : const Color(0xFF1E293B);
    final HSLColor hsl = HSLColor.fromColor(fallbackColor);
    return CardColorData(
      primary: fallbackColor,
      secondary: hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor(),
      accent: hsl.withLightness((hsl.lightness + 0.1).clamp(0.0, 1.0)).toColor(),
      name: 'Custom',
    );
  }
}

