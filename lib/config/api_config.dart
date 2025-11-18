import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Flip to true if you are running on Android emulator
  static const bool useAndroidEmulator = false;

  // Production URL
  static const String _productionUrl = 'https://vpg-9wlv.onrender.com';
  
  // For local development only
  static const int _port = 5000;
  static String get _local =>
      'http://127.0.0.1:_port'.replaceFirst('_port', _port.toString());
  static String get _androidEmu =>
      'http://10.0.2.2:_port'.replaceFirst('_port', _port.toString());

  // Base server URL - use production URL for web, local for development
  static String get base {
    if (kIsWeb) {
      return _productionUrl; // Always use production for web
    }
    return useAndroidEmulator ? _androidEmu : _local;
  }

  // Common prefixes
  static String get api => '$base/api';
  static String get auth => '$base/auth';

  static Map<String, String> jsonHeaders([String? token]) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}