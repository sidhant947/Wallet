import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = true;
  bool _useSystemFont = false;
  static const String _themeKey = 'isDarkMode';
  static const String _fontKey = 'useSystemFont';

  bool get isDarkMode => _isDarkMode;
  bool get useSystemFont => _useSystemFont;

  ThemeMode get currentTheme => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  // Initialize theme from saved preferences
  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? true; // Default to dark mode
    _useSystemFont = prefs.getBool(_fontKey) ?? false; // Default to custom font
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  Future<void> toggleFont() async {
    _useSystemFont = !_useSystemFont;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_fontKey, _useSystemFont);
    notifyListeners();
  }

  // Theme-aware colors
  Color get primaryColor => _isDarkMode ? Colors.white : Colors.black;
  Color get secondaryColor => _isDarkMode ? Colors.white70 : Colors.black87;
  Color get backgroundColor => _isDarkMode ? Colors.black : Colors.white;
  Color get surfaceColor =>
      _isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100;
  Color get cardColor => _isDarkMode ? Colors.grey.shade800 : Colors.white;
  Color get borderColor => _isDarkMode ? Colors.white30 : Colors.black26;
  Color get accentColor =>
      _isDarkMode ? Colors.blueAccent.shade400 : Colors.blue.shade600;

  // Get theme-aware text style
  TextStyle getTextStyle({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? primaryColor,
      fontFamily: _useSystemFont ? null : "Bebas",
    );
  }
}
