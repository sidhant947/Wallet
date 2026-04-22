import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// REMOVED: StartupScreen enum is no longer needed

class StartupSettingsProvider with ChangeNotifier {
  bool _showAuthenticationScreen = true;
  int _defaultScreenIndex = 0;
  bool _hideIdentityAndLoyalty = false;
  String _selectedCurrencyCode = 'INR';
  String _selectedCurrencySymbol = '₹';

  static const String _authKey = 'showAuthenticationScreen';
  static const String _defaultScreenKey = 'defaultScreenIndex';
  static const String _hideKey = 'hideIdentityAndLoyalty';
  static const String _currencyCodeKey = 'selectedCurrencyCode';
  static const String _currencySymbolKey = 'selectedCurrencySymbol';

  bool get showAuthenticationScreen => _showAuthenticationScreen;
  int get defaultScreenIndex => _defaultScreenIndex;
  bool get hideIdentityAndLoyalty => _hideIdentityAndLoyalty;
  String get selectedCurrencyCode => _selectedCurrencyCode;
  String get selectedCurrencySymbol => _selectedCurrencySymbol;

  static const List<Map<String, String>> majorCurrencies = [
    {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
    {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
    {'code': 'AUD', 'symbol': 'A\$', 'name': 'Australian Dollar'},
    {'code': 'CAD', 'symbol': 'C\$', 'name': 'Canadian Dollar'},
    {'code': 'CHF', 'symbol': 'CHF', 'name': 'Swiss Franc'},
    {'code': 'CNY', 'symbol': '¥', 'name': 'Chinese Yuan'},
    {'code': 'NZD', 'symbol': 'NZ\$', 'name': 'New Zealand Dollar'},
  ];

  // Initialize settings from saved preferences
  Future<void> loadStartupSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _showAuthenticationScreen = prefs.getBool(_authKey) ?? true;
    _defaultScreenIndex = prefs.getInt(_defaultScreenKey) ?? 0;
    _hideIdentityAndLoyalty = prefs.getBool(_hideKey) ?? false;
    _selectedCurrencyCode = prefs.getString(_currencyCodeKey) ?? 'INR';
    _selectedCurrencySymbol = prefs.getString(_currencySymbolKey) ?? '₹';
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

  Future<void> setCurrency(String code, String symbol) async {
    _selectedCurrencyCode = code;
    _selectedCurrencySymbol = symbol;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyCodeKey, _selectedCurrencyCode);
    await prefs.setString(_currencySymbolKey, _selectedCurrencySymbol);
    notifyListeners();
  }
}
