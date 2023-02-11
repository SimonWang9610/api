import 'dart:typed_data';
import 'dart:convert';

import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

import 'models/error.dart';

/// Converts [input] into a [Uint8List].
///
/// If [input] is a [TypedData], this just returns a view on [input].
Uint8List toUint8List(List<int> input) {
  if (input is Uint8List) return input;
  if (input is TypedData) {
    return Uint8List.view((input as TypedData).buffer);
  }
  return Uint8List.fromList(input);
}

/// Returns the [Encoding] that corresponds to [charset].
///
/// Throws a [FormatException] if no [Encoding] was found that corresponds to
/// [charset].
///
/// [charset] may not be null.
Encoding requiredEncodingForCharset(String charset) =>
    Encoding.getByName(charset) ??
    (throw FormatException('Unsupported encoding "$charset".'));

String mapToQuery(Map<String, String> map, {Encoding? encoding}) {
  var pairs = <List<String>>[];
  map.forEach((key, value) => pairs.add([
        Uri.encodeQueryComponent(key, encoding: encoding ?? utf8),
        Uri.encodeQueryComponent(value, encoding: encoding ?? utf8)
      ]));
  return pairs.map((pair) => '${pair[0]}=${pair[1]}').join('&');
}

void removeContentLengthHeader(Map<String, String> headers) {
  for (final field in ["content-length", "ContentLength", "Content-Length"]) {
    headers.remove(field);
  }
}

/// Returns the [Encoding] that corresponds to [charset].
///
/// Returns [fallback] if [charset] is null or if no [Encoding] was found that
/// corresponds to [charset].
Encoding encodingForCharset(String? charset, [Encoding fallback = latin1]) {
  if (charset == null) return fallback;
  return Encoding.getByName(charset) ?? fallback;
}

final _asciiOnly = RegExp(r'^[\x00-\x7F]+$');

/// Returns whether [string] is composed entirely of ASCII-compatible
/// characters.
bool isPlainAscii(String string) => _asciiOnly.hasMatch(string);

/// infer the [MediaType] from the [filename]
MediaType? getMediaTypeFromFilename(String? filename) {
  String? mime = filename != null ? lookupMimeType(filename) : null;

  return mime != null ? MediaType.parse(mime) : null;
}

ApiError assureApiError(Object e) {
  if (e is ApiError) {
    return e;
  } else {
    return ApiError(
      type: ErrorType.other,
      message: "$e",
    );
  }
}
