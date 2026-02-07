import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported theme modes for the app.
enum AppThemeMode {
  light,
  dark,
  black,
}

// Helpers for persisting enum values.
extension AppThemeModeX on AppThemeMode {
  String get key {
    switch (this) {
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
      case AppThemeMode.black:
        return 'black';
    }
  }

  static AppThemeMode fromKey(String? key) {
    switch (key) {
      case 'dark':
        return AppThemeMode.dark;
      case 'black':
        return AppThemeMode.black;
      case 'light':
      default:
        return AppThemeMode.light;
    }
  }
}

/// Manages persisted theme mode and notifies the UI.
class ThemeService {
  static const String _themeKey = 'app_theme_mode';
  static final ValueNotifier<AppThemeMode> modeNotifier =
      ValueNotifier<AppThemeMode>(AppThemeMode.light);

  // Load saved theme mode during app startup.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themeKey);
    modeNotifier.value = AppThemeModeX.fromKey(saved);
  }

  // Convert AppThemeMode to Flutter ThemeMode.
  static ThemeMode toThemeMode(AppThemeMode mode) {
    return mode == AppThemeMode.light ? ThemeMode.light : ThemeMode.dark;
  }

  // Persist theme selection and notify listeners.
  static Future<void> setMode(AppThemeMode mode) async {
    if (modeNotifier.value == mode) return;
    modeNotifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.key);
  }
}


