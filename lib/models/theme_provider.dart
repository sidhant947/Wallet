// lib/models/theme_provider.dart

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

  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? true;
    _useSystemFont = prefs.getBool(_fontKey) ?? false;
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

  static const PageTransitionsTheme _pageTransitionsTheme =
      PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      );

  TextStyle getTextStyle({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color:
          color ??
          (_isDarkMode ? Colors.white.withOpacity(0.87) : Colors.black87),
    );
  }

  // --- NEW DARK THEME (PURE BLACK + WHITE ACCENT) ---
  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    cardColor: Colors.black, // Cards will be distinguished by a border
    fontFamily: _useSystemFont ? null : 'Bebas',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Bebas',
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
    drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF1A1A1A)),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    ),
    listTileTheme: const ListTileThemeData(iconColor: Colors.white70),
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      secondary: Colors.white,
      surface: Color(0xFF1A1A1A),
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.white,
      error: Colors.redAccent,
    ),
    pageTransitionsTheme: _pageTransitionsTheme,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade800),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade800),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );

  // --- NEW LIGHT THEME (PURE WHITE + RED ACCENT) ---
  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    cardColor: Colors.white,
    fontFamily: _useSystemFont ? null : 'Bebas',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Bebas',
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),
    drawerTheme: const DrawerThemeData(backgroundColor: Colors.white),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.red.shade700,
      foregroundColor: Colors.white,
    ),
    listTileTheme: const ListTileThemeData(iconColor: Colors.black54),
    colorScheme: ColorScheme.light(
      primary: Colors.red.shade700,
      secondary: Colors.red.shade600,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black,
      error: Colors.red.shade900,
    ),
    pageTransitionsTheme: _pageTransitionsTheme,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
