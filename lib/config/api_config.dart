import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Flip to true if you are running on Android emulator
  // (emulator cannot reach 127.0.0.1 of the host; it uses 10.0.2.2)
  static const bool useAndroidEmulator = false;

  // Backend currently runs on port 5000 (see server/app.py)
  static const int _port = 5000;

  static String get _local =>
      'http://127.0.0.1:_port'.replaceFirst('_port', _port.toString());
  static String get _androidEmu =>
      'http://10.0.2.2:_port'.replaceFirst('_port', _port.toString());

  // Base server URL (no path prefix)
  static String get base =>
      useAndroidEmulator && !kIsWeb ? _androidEmu : _local;

  // Common prefixes
  static String get api => '$base/api';
  static String get auth => '$base/auth';

  static Map<String, String> jsonHeaders([String? token]) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}
