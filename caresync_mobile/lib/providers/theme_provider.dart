import 'package:flutter/material.dart';

import '../core/storage/local_storage.dart';

/// State management for app-wide ThemeMode (Light vs Dark).
class ThemeProvider with ChangeNotifier {
  final LocalStorage _storage;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider({LocalStorage? storage})
      : _storage = storage ?? LocalStorage() {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void _loadTheme() {
    final savedMode = _storage.getThemeMode();
    if (savedMode != null) {
      if (savedMode == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (savedMode == 'light') {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.system;
      }
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
      await _storage.saveThemeMode('light');
    } else {
      _themeMode = ThemeMode.dark;
      await _storage.saveThemeMode('dark');
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    String modeString = 'system';
    if (mode == ThemeMode.dark) modeString = 'dark';
    if (mode == ThemeMode.light) modeString = 'light';
    await _storage.saveThemeMode(modeString);
    notifyListeners();
  }
}
