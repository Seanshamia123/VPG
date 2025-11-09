// Minimal stubs to emulate dart:html types on non-web platforms.

/// Minimal Blob stub: stores raw bytes (not used on non-web).
class Blob {
  final List<dynamic> parts;
  final String? type;

  Blob(this.parts, [this.type]);
}

/// Minimal File stub: stores blobs and a filename (not used on non-web).
class File {
  final List<Blob> parts;
  final String name;
  final Map<String, dynamic>? _meta;

  File(this.parts, this.name, [this._meta]);
}
