import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AutoBackupProvider with ChangeNotifier {
  bool _isEnabled = false;
  String _backupPath = '';
  String _backupPassword = '';
  String _backupUri = '';

  bool get isEnabled => _isEnabled;
  String get backupPath => _backupPath;
  String get backupPassword => _backupPassword;
  String get backupUri => _backupUri;

  static const String _keyEnabled = 'autoBackupEnabled';
  static const String _keyPath = 'autoBackupPath';
  static const String _keyPassword = 'autoBackupPassword';
  static const String _keyUri = 'autoBackupUri';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_keyEnabled) ?? false;
    _backupPath = prefs.getString(_keyPath) ?? '';
    _backupPassword = prefs.getString(_keyPassword) ?? '';
    _backupUri = prefs.getString(_keyUri) ?? '';
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    _isEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, value);
    notifyListeners();
  }

  Future<void> setBackupPath(String path) async {
    _backupPath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPath, path);
    notifyListeners();
  }

  Future<void> setBackupUri(String uri) async {
    _backupUri = uri;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUri, uri);
    notifyListeners();
  }

  Future<void> setBackupPassword(String password) async {
    _backupPassword = password;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPassword, password);
    notifyListeners();
  }

  bool get isConfigured =>
      _isEnabled && _backupUri.isNotEmpty && _backupPassword.isNotEmpty;

  String get displayPath {
    if (_backupUri.isEmpty) return _backupPath;
    try {
      final uri = Uri.parse(_backupUri);
      final segments = uri.pathSegments;
      if (segments.length >= 2) {
        return segments.last;
      }
    } catch (_) {}
    return _backupPath;
  }
}
