import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// REMOVED: StartupScreen enum is no longer needed

class StartupSettingsProvider with ChangeNotifier {
  bool _showAuthenticationScreen = true;
  static const String _authKey = 'showAuthenticationScreen';

  bool get showAuthenticationScreen => _showAuthenticationScreen;

  // Initialize settings from saved preferences
  Future<void> loadStartupSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _showAuthenticationScreen = prefs.getBool(_authKey) ?? true;
    notifyListeners();
  }

  Future<void> toggleAuthenticationScreen() async {
    _showAuthenticationScreen = !_showAuthenticationScreen;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_authKey, _showAuthenticationScreen);
    notifyListeners();
  }
}
