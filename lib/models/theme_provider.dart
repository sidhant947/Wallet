// lib/models/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Enum for the available theme options
enum ThemePreference { light, dark, system }

class NoTransitionsBuilder extends PageTransitionsBuilder {
  const NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

class ThemeProvider with ChangeNotifier {
  ThemePreference _themePreference = ThemePreference.system;
  bool _isDarkMode = false;
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
        return ThemeMode.system;
    }
  }

  // Initializes the provider, loading preferences and setting up listeners
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final themeIndex =
        prefs.getInt(_themePreferenceKey) ?? ThemePreference.system.index;
    _themePreference = ThemePreference.values[themeIndex];
    _useSystemFont = prefs.getBool(_fontKey) ?? false;
    _updateDarkModeState();

    var platformDispatcher = SchedulerBinding.instance.platformDispatcher;
    platformDispatcher.onPlatformBrightnessChanged = () {
      if (_themePreference == ThemePreference.system) {
        _updateDarkModeState();
        notifyListeners();
      }
    };
    notifyListeners();
  }

  void _updateDarkModeState() {
    if (_themePreference == ThemePreference.light) {
      _isDarkMode = false;
    } else if (_themePreference == ThemePreference.dark) {
      _isDarkMode = true;
    } else {
      final brightness =
          SchedulerBinding.instance.platformDispatcher.platformBrightness;
      _isDarkMode = brightness == Brightness.dark;
    }
  }

  Future<void> setThemePreference(ThemePreference preference) async {
    if (_themePreference == preference) return;
    _themePreference = preference;
    _updateDarkModeState();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themePreferenceKey, preference.index);
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
          TargetPlatform.android: NoTransitionsBuilder(),
          TargetPlatform.iOS: NoTransitionsBuilder(),
          TargetPlatform.linux: NoTransitionsBuilder(),
          TargetPlatform.macOS: NoTransitionsBuilder(),
          TargetPlatform.windows: NoTransitionsBuilder(),
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
      color: color ?? (_isDarkMode ? Colors.white : Colors.black),
    );
  }

  // --- LIQUID GLASS DESIGN HELPERS ---

  /// Returns the glass background color based on theme
  Color get glassBackground => _isDarkMode
      ? Colors.white.withValues(alpha: 0.08)
      : Colors.black.withValues(alpha: 0.04);

  /// Returns the glass border color based on theme
  Color get glassBorder => _isDarkMode
      ? Colors.white.withValues(alpha: 0.15)
      : Colors.black.withValues(alpha: 0.08);

  /// Returns a subtle glass highlight for top edges
  Color get glassHighlight => _isDarkMode
      ? Colors.white.withValues(alpha: 0.2)
      : Colors.white.withValues(alpha: 0.7);

  /// Returns card surface color for glass effect
  Color get glassSurface =>
      _isDarkMode ? const Color(0xFF0A0A0A) : const Color(0xFFF8F8F8);

  /// Returns the elevated glass surface color
  Color get glassElevatedSurface =>
      _isDarkMode ? const Color(0xFF121212) : Colors.white;

  // --- TYPOGRAPHY BEST PRACTICES ---
  TextTheme _buildTextTheme(bool isDark) {
    final Color color = isDark ? Colors.white : Colors.black;
    final Color secondaryColor = isDark ? Colors.white70 : Colors.black87;

    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: color,
        letterSpacing: -1.0,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: color,
        letterSpacing: -0.8,
        height: 1.2,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: color,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.3,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.3,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.4,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: color,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: color,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: secondaryColor,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.5,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
        letterSpacing: 0.5,
      ),
    );
  }

  // --- PURE BLACK DARK THEME ---
  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    canvasColor: Colors.black,
    cardColor: const Color(0xFF0A0A0A),
    fontFamily: _useSystemFont ? null : 'ZSpace',
    textTheme: _buildTextTheme(true),
    primaryColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontFamily: 'ZSpace',
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Colors.black,
      surfaceTintColor: Colors.transparent,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: Colors.white70,
      textColor: Colors.white,
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    dividerColor: Colors.white.withValues(alpha: 0.1),
    colorScheme: ColorScheme.dark(
      primary: Colors.white,
      secondary: Colors.white,
      surface: Colors.black,
      surfaceContainerHighest: const Color(0xFF0A0A0A),
      surfaceContainer: const Color(0xFF0A0A0A),
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.white,
      error: Colors.red.shade400,
      outline: Colors.white.withValues(alpha: 0.15),
      primaryContainer: Colors.white.withValues(alpha: 0.1),
      onPrimaryContainer: Colors.white,
    ),
    pageTransitionsTheme: _pageTransitionsTheme,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white, width: 1.5),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF0A0A0A),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colors.white,
      contentTextStyle: const TextStyle(color: Colors.black),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.black,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.white.withValues(alpha: 0.15),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: Colors.white);
        }
        return IconThemeData(color: Colors.white.withValues(alpha: 0.5));
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          );
        }
        return TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12);
      }),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
      indicatorColor: Colors.white,
      dividerColor: Colors.transparent,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.black;
        return Colors.white.withValues(alpha: 0.6);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return Colors.white.withValues(alpha: 0.2);
      }),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Colors.white),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.black;
          return Colors.white.withValues(alpha: 0.6);
        }),
        side: WidgetStateProperty.all(
          BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white.withValues(alpha: 0.08),
      labelStyle: const TextStyle(color: Colors.white),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: const Color(0xFF0A0A0A),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.black,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
  );

  // --- PURE WHITE LIGHT THEME ---
  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    canvasColor: Colors.white,
    cardColor: const Color(0xFFF5F5F5),
    fontFamily: _useSystemFont ? null : 'ZSpace',
    textTheme: _buildTextTheme(false),
    primaryColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontFamily: 'ZSpace',
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: Colors.black54,
      textColor: Colors.black,
    ),
    iconTheme: const IconThemeData(color: Colors.black),
    dividerColor: Colors.black.withValues(alpha: 0.08),
    colorScheme: ColorScheme.light(
      primary: Colors.black,
      secondary: Colors.black,
      surface: Colors.white,
      surfaceContainerHighest: const Color(0xFFF5F5F5),
      surfaceContainer: const Color(0xFFF8F8F8),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black,
      error: Colors.red.shade700,
      outline: Colors.black.withValues(alpha: 0.1),
      primaryContainer: Colors.black.withValues(alpha: 0.08),
      onPrimaryContainer: Colors.black,
    ),
    pageTransitionsTheme: _pageTransitionsTheme,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.03),
      hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.4)),
      labelStyle: TextStyle(color: Colors.black.withValues(alpha: 0.6)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.black, width: 1.5),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colors.black,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.black.withValues(alpha: 0.1),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: Colors.black);
        }
        return IconThemeData(color: Colors.black.withValues(alpha: 0.4));
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          );
        }
        return TextStyle(color: Colors.black.withValues(alpha: 0.4), fontSize: 12);
      }),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: Colors.black,
      unselectedLabelColor: Colors.black.withValues(alpha: 0.4),
      indicatorColor: Colors.black,
      dividerColor: Colors.transparent,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return Colors.black.withValues(alpha: 0.4);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.black;
        return Colors.black.withValues(alpha: 0.15);
      }),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black,
        side: BorderSide(color: Colors.black.withValues(alpha: 0.2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Colors.black),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.black;
          return Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return Colors.black.withValues(alpha: 0.5);
        }),
        side: WidgetStateProperty.all(
          BorderSide(color: Colors.black.withValues(alpha: 0.1)),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.black.withValues(alpha: 0.05),
      labelStyle: const TextStyle(color: Colors.black),
      side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
  );
}
