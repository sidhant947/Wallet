import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// REMOVED: StartupScreen enum is no longer needed

class StartupSettingsProvider with ChangeNotifier {
  bool _showAuthenticationScreen = true;
  int _defaultScreenIndex = 0;
  bool _hideIdentityAndLoyalty = false;

  static const String _authKey = 'showAuthenticationScreen';
  static const String _defaultScreenKey = 'defaultScreenIndex';
  static const String _hideKey = 'hideIdentityAndLoyalty';

  bool get showAuthenticationScreen => _showAuthenticationScreen;
  int get defaultScreenIndex => _defaultScreenIndex;
  bool get hideIdentityAndLoyalty => _hideIdentityAndLoyalty;

  // Initialize settings from saved preferences
  Future<void> loadStartupSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _showAuthenticationScreen = prefs.getBool(_authKey) ?? true;
    _defaultScreenIndex = prefs.getInt(_defaultScreenKey) ?? 0;
    _hideIdentityAndLoyalty = prefs.getBool(_hideKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleAuthenticationScreen() async {
    _showAuthenticationScreen = !_showAuthenticationScreen;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_authKey, _showAuthenticationScreen);
    notifyListeners();
  }

  Future<void> setDefaultScreen(int index) async {
    _defaultScreenIndex = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_defaultScreenKey, _defaultScreenIndex);
    notifyListeners();
  }

  Future<void> toggleHideIdentityAndLoyalty() async {
    _hideIdentityAndLoyalty = !_hideIdentityAndLoyalty;
    if (_hideIdentityAndLoyalty) {
      _defaultScreenIndex = 0; // Force default to payment if others hidden
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hideKey, _hideIdentityAndLoyalty);
    await prefs.setInt(_defaultScreenKey, _defaultScreenIndex);
    notifyListeners();
  }
}
