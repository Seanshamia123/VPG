/// Helper for creating platform-specific File objects
/// Handles the difference between dart:io File (mobile/desktop) and dart:html File (web)
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional imports
import 'dart:io' as io show File;
import 'dart:html' as html show File;

/// Creates a File object that works across platforms
/// 
/// On web: Creates a dart:html File from bytes
/// On mobile/desktop: Returns the dart:io File from the path
/// 
/// For web usage:
/// ```dart
/// final bytes = await xFile.readAsBytes();
/// final file = await createPlatformFile(bytes, xFile.name);
/// ```
/// 
/// For mobile/desktop usage:
/// ```dart
/// final file = await createPlatformFileFromPath(xFile.path);
/// ```
Future<dynamic> createPlatformFile(Uint8List bytes, String filename) async {
  if (kIsWeb) {
    // Web: Create html.File from bytes
    return html.File([bytes], filename);
  } else {
    // This shouldn't be called on non-web platforms
    throw UnsupportedError('createPlatformFile with bytes should only be used on web');
  }
}

/// Creates a File from a path (mobile/desktop only)
dynamic createPlatformFileFromPath(String path) {
  if (kIsWeb) {
    throw UnsupportedError('File paths are not supported on web');
  } else {
    return io.File(path);
  }
}