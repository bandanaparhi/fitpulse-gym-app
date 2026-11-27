import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'image_file_picker.dart';

/// Opens a browser `<input type="file" accept="image/*">` dialog on Flutter Web.
Future<PickedImageFile?> pickImageFilePlatform() async {
  final completer = Completer<PickedImageFile?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = 'image/png,image/jpeg,image/webp,image/*';

  void handleCancel(web.Event _) {
    if (!completer.isCompleted) completer.complete(null);
  }

  Future<void> handleChange(web.Event _) async {
    try {
      final files = input.files;
      if (files == null || files.length == 0) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }
      final file = files.item(0);
      if (file == null) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }
      final buffer = await file.arrayBuffer().toDart;
      final bytes = buffer.toDart.asUint8List();
      if (!completer.isCompleted) {
        completer.complete(PickedImageFile(fileName: file.name, bytes: bytes));
      }
    } catch (_) {
      if (!completer.isCompleted) completer.complete(null);
    }
  }

  input.addEventListener('cancel', handleCancel.toJS);
  input.addEventListener(
    'change',
    ((web.Event e) {
      handleChange(e);
    }).toJS,
  );
  input.click();
  return completer.future;
}
