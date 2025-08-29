import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum StartupScreen { home, loyalty, identity }

class StartupSettingsProvider with ChangeNotifier {
  bool _showAuthenticationScreen = true;
  StartupScreen _defaultScreen = StartupScreen.home;

  static const String _authKey = 'showAuthenticationScreen';
  static const String _defaultScreenKey = 'defaultScreen';

  bool get showAuthenticationScreen => _showAuthenticationScreen;
  StartupScreen get defaultScreen => _defaultScreen;

  // Initialize settings from saved preferences
  Future<void> loadStartupSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _showAuthenticationScreen = prefs.getBool(_authKey) ?? true;

    final screenIndex = prefs.getInt(_defaultScreenKey) ?? 0;
    _defaultScreen = StartupScreen.values[screenIndex];

    notifyListeners();
  }

  Future<void> toggleAuthenticationScreen() async {
    _showAuthenticationScreen = !_showAuthenticationScreen;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_authKey, _showAuthenticationScreen);
    notifyListeners();
  }

  Future<void> setDefaultScreen(StartupScreen screen) async {
    _defaultScreen = screen;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_defaultScreenKey, screen.index);
    notifyListeners();
  }

  String getScreenDisplayName(StartupScreen screen) {
    switch (screen) {
      case StartupScreen.home:
        return 'Home Screen';
      case StartupScreen.loyalty:
        return 'Loyalty Screen';
      case StartupScreen.identity:
        return 'Identity Screen';
    }
  }
}
