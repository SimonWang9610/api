import 'dart:convert';

import 'dart:typed_data';

import 'package:http_parser/http_parser.dart';

import 'multipart_stub.dart' if (dart.library.io) "multipart_io.dart";

import '../models/byte_stream.dart';
import '../utils.dart';

/// [field] indicates the key for this file
/// [length] must be know in advance
///
/// [filename] and [contentType]
///
/// 1) provide [filename] as soon as possible so that the server-side could decode the binary data into the original file correctly
/// 2) if not [MediaType] is specified for this file, [contentType] would be inferred from [filename].
///   if none of them is applied, [contentType] would default to `application/octet-stream`
///
class MultipartFile {
  final String field;
  final int length;
  final String? filename;

  /// The content-type of the file.
  ///
  /// Defaults to `application/octet-stream`.
  final MediaType contentType;

  /// The stream that will emit the file's contents.
  final ByteStream _stream;

  bool get isFinalized => _isFinalized;
  bool _isFinalized = false;

  MultipartFile(this.field, Stream<List<int>> stream, this.length,
      {this.filename, MediaType? contentType})
      : _stream = stream.cast<Uint8List>(),
        contentType = contentType ??
            getMediaTypeFromFilename(filename) ??
            MediaType('application', 'octet-stream');

  factory MultipartFile.fromBytes(String field, List<int> value,
      {String? filename, MediaType? contentType}) {
    final stream = Stream.value(value);
    return MultipartFile(
      field,
      stream,
      value.length,
      filename: filename,
      contentType: contentType,
    );
  }

  /// Creates a new [MultipartFile] from a string.
  ///
  /// The encoding to use when translating [value] into bytes is taken from
  /// [contentType] if it has a charset set. Otherwise, it defaults to UTF-8.
  /// [contentType] currently defaults to `text/plain; charset=utf-8`, but in
  /// the future may be inferred from [filename].
  factory MultipartFile.fromString(String field, String value,
      {String? filename, MediaType? contentType}) {
    contentType ??= MediaType('text', 'plain');
    var encoding = encodingForCharset(contentType.parameters['charset'], utf8);
    contentType = contentType.change(parameters: {'charset': encoding.name});

    return MultipartFile.fromBytes(field, encoding.encode(value),
        filename: filename, contentType: contentType);
  }

  static Future<MultipartFile> fromPath(String field, String filePath,
          {String? filename, MediaType? contentType}) =>
      multipartFileFromPath(field, filePath,
          filename: filename, contentType: contentType);

  // Finalizes the file in preparation for it being sent as part of a
  // [MultipartRequest]. This returns a [ByteStream] that should emit the body
  // of the file. The stream may be closed to indicate an empty file.
  ByteStream finalize() {
    if (isFinalized) {
      throw StateError("Can't finalize a finalized MultipartFile.");
    }
    _isFinalized = true;
    return _stream;
  }

  @override
  String toString() {
    return "MultipartFile(name: $filename, type: $contentType, length: $length)";
  }
}
