import 'dart:typed_data';

import 'image_file_picker_stub.dart'
    if (dart.library.js_interop) 'image_file_picker_web.dart' as impl;

/// Picked image payload returned by the platform file chooser.
class PickedImageFile {
  final String fileName;
  final Uint8List bytes;

  const PickedImageFile({
    required this.fileName,
    required this.bytes,
  });
}

/// Opens an image file chooser on supported platforms (Web) and returns the
/// selected bytes, or `null` if cancelled or unsupported.
Future<PickedImageFile?> pickImageFile() => impl.pickImageFilePlatform();
