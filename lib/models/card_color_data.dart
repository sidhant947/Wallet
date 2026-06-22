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
}

// Premium color palette - Modern 2024 Design
const Map<String, CardColorData> cardColorPalette = {
  'obsidian': CardColorData(
    primary: Color(0xFF0F0F0F),
    secondary: Color(0xFF1A1A1A),
    accent: Color(0xFF262626),
    name: 'Obsidian',
  ),
  'midnight': CardColorData(
    primary: Color(0xFF0F172A),
    secondary: Color(0xFF1E293B),
    accent: Color(0xFF334155),
    name: 'Midnight',
  ),
  'slate': CardColorData(
    primary: Color(0xFF1E293B),
    secondary: Color(0xFF334155),
    accent: Color(0xFF475569),
    name: 'Slate',
  ),
  'indigo': CardColorData(
    primary: Color(0xFF1E1B4B),
    secondary: Color(0xFF312E81),
    accent: Color(0xFF4338CA),
    name: 'Indigo',
  ),
  'violet': CardColorData(
    primary: Color(0xFF2E1065),
    secondary: Color(0xFF4C1D95),
    accent: Color(0xFF6D28D9),
    name: 'Violet',
  ),
  'ocean': CardColorData(
    primary: Color(0xFF0C4A6E),
    secondary: Color(0xFF075985),
    accent: Color(0xFF0284C7),
    name: 'Ocean',
  ),
  'teal': CardColorData(
    primary: Color(0xFF134E4A),
    secondary: Color(0xFF115E59),
    accent: Color(0xFF0D9488),
    name: 'Teal',
  ),
  'emerald': CardColorData(
    primary: Color(0xFF064E3B),
    secondary: Color(0xFF065F46),
    accent: Color(0xFF059669),
    name: 'Emerald',
  ),
  'amber': CardColorData(
    primary: Color(0xFF78350F),
    secondary: Color(0xFF92400E),
    accent: Color(0xFFD97706),
    name: 'Amber',
  ),
  'rose': CardColorData(
    primary: Color(0xFF4C0519),
    secondary: Color(0xFF881337),
    accent: Color(0xFFE11D48),
    name: 'Rose',
  ),
};
