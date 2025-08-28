// lib/theme/theme_controller.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);
  static const _key = 'app_theme_mode';

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_key);
    switch (v) {
      case 'dark':
        themeMode.value = ThemeMode.dark;
        break;
      case 'light':
        themeMode.value = ThemeMode.light;
        break;
      default:
        themeMode.value = ThemeMode.system;
    }
  }

  static Future<void> set(ThemeMode mode) async {
    themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode == ThemeMode.dark ? 'dark' : mode == ThemeMode.light ? 'light' : 'system');
  }
}

