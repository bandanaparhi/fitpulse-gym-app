import 'dart:js_interop';
import 'dart:typed_data';

@JS('Blob')
extension type _JSBlob._(JSObject _) implements JSObject {
  external factory _JSBlob(JSArray<JSAny> parts, _BlobOptions options);
}

@JS()
@anonymous
extension type _BlobOptions._(JSObject _) implements JSObject {
  external factory _BlobOptions({String type});
}

@JS('URL.createObjectURL')
external String _createObjectURL(_JSBlob blob);

@JS('URL.revokeObjectURL')
external void _revokeObjectURL(String url);

@JS('document.createElement')
external _HTMLAnchorElement _createAnchorElement(String tagName);

extension type _HTMLAnchorElement._(JSObject _) implements JSObject {
  external set href(String value);
  external set download(String value);
  external void click();
}

Future<void> savePdfBytes({
  required Uint8List bytes,
  required String fileName,
}) async {
  final blob = _JSBlob(
    <JSAny>[bytes.toJS].toJS,
    _BlobOptions(type: 'application/pdf'),
  );
  final url = _createObjectURL(blob);
  try {
    final anchor = _createAnchorElement('a')
      ..href = url
      ..download = fileName;
    anchor.click();
  } finally {
    _revokeObjectURL(url);
  }
}
