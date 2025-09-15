import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController {
  static const _prefKeyName = 'selected_language'; // human string e.g. "english"
  static const _prefKeyCode = 'selected_language_code'; // BCP-47 tag e.g. "en" or "en_US"

  // Default to English until loaded.
  static final ValueNotifier<Locale> locale = ValueNotifier<Locale>(const Locale('en'));

  // Mapping by human-readable names we previously stored server-side.
  static const Map<String, Locale> _nameToLocale = {
    'english': Locale('en'),
    'spanish': Locale('es'),
    'french': Locale('fr'),
    'german': Locale('de'),
    'italian': Locale('it'),
    'hindi': Locale('hi'),
    'thai': Locale('th'),
    'chinese': Locale('zh'),
    'japanese': Locale('ja'),
    'korean': Locale('ko'),
    'arabic': Locale('ar'),
    'russian': Locale('ru'),
    'portuguese': Locale('pt'),
    'dutch': Locale('nl'),
    'turkish': Locale('tr'),
    'polish': Locale('pl'),
  };

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    // Prefer stored code (BCP-47), else fallback to stored name, else device locale.
    final savedCode = prefs.getString(_prefKeyCode);
    if (savedCode != null && savedCode.isNotEmpty) {
      locale.value = _parseLocaleTag(savedCode);
      return;
    }

    final savedName = prefs.getString(_prefKeyName)?.toLowerCase().trim();
    if (savedName != null && _nameToLocale.containsKey(savedName)) {
      locale.value = _nameToLocale[savedName]!;
      return;
    }

    // Device locale fallback
    final device = PlatformDispatcher.instance.locale;
    if (device != null) locale.value = device;
  }

  static Future<void> set(Locale newLocale) async {
    locale.value = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyCode, _toTag(newLocale));
  }

  static Future<void> setByLanguageName(String name) async {
    final key = name.toLowerCase().trim();
    final loc = _nameToLocale[key] ?? const Locale('en');
    await set(loc);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyName, key);
  }

  static Locale _parseLocaleTag(String tag) {
    final parts = tag.replaceAll('-', '_').split('_');
    if (parts.length == 1) return Locale(parts[0]);
    if (parts.length == 2) return Locale(parts[0], parts[1]);
    return Locale(parts[0]);
  }

  static String _toTag(Locale l) => l.countryCode == null || l.countryCode!.isEmpty
      ? l.languageCode
      : '${l.languageCode}_${l.countryCode}';
}
