// lib/models/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Enum for the available theme options
enum ThemePreference { light, dark, system }

class ThemeProvider with ChangeNotifier {
  ThemePreference _themePreference = ThemePreference.system;
  bool _isDarkMode = false; // This will now be a derived state
  bool _useSystemFont = false;

  static const String _themePreferenceKey = 'themePreference';
  static const String _fontKey = 'useSystemFont';

  // Getters for the current state
  ThemePreference get themePreference => _themePreference;
  bool get isDarkMode => _isDarkMode;
  bool get useSystemFont => _useSystemFont;

  // Determines the ThemeMode for the MaterialApp
  ThemeMode get currentTheme {
    switch (_themePreference) {
      case ThemePreference.light:
        return ThemeMode.light;
      case ThemePreference.dark:
        return ThemeMode.dark;
      case ThemePreference.system:
      default:
        return ThemeMode.system;
    }
  }

  // Initializes the provider, loading preferences and setting up listeners
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Load saved theme preference, defaulting to 'system'
    final themeIndex =
        prefs.getInt(_themePreferenceKey) ?? ThemePreference.system.index;
    _themePreference = ThemePreference.values[themeIndex];

    // Load font preference
    _useSystemFont = prefs.getBool(_fontKey) ?? false;

    // Set the initial dark mode state based on preference
    _updateDarkModeState();

    // Listen for changes in the system's theme
    SchedulerBinding.instance.window.onPlatformBrightnessChanged = () {
      if (_themePreference == ThemePreference.system) {
        _updateDarkModeState();
        notifyListeners();
      }
    };

    notifyListeners();
  }

  // Helper method to set the internal _isDarkMode flag correctly
  void _updateDarkModeState() {
    if (_themePreference == ThemePreference.light) {
      _isDarkMode = false;
    } else if (_themePreference == ThemePreference.dark) {
      _isDarkMode = true;
    } else {
      // When set to system, check the actual system brightness
      final brightness = SchedulerBinding.instance.window.platformBrightness;
      _isDarkMode = brightness == Brightness.dark;
    }
  }

  // Sets the new theme preference and saves it
  Future<void> setThemePreference(ThemePreference preference) async {
    if (_themePreference == preference) return;

    _themePreference = preference;
    _updateDarkModeState();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themePreferenceKey, preference.index);

    notifyListeners();
  }

  // Unchanged methods below...
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
