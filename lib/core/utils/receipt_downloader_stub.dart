import 'dart:typed_data';

Future<void> savePdfBytes({
  required Uint8List bytes,
  required String fileName,
}) async {
  // Non-web / test environments rely on in-app confirmation without dart:io file prompts.
}
