// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../models/byte_stream.dart';
import '../multipart/form_data.dart';
import '../multipart/multipart_file.dart';
import '../utils.dart';

import 'base_request.dart';
import 'content_type_helper.dart';

final _newlineRegExp = RegExp(r'\r\n|\r|\n');

/// A `multipart/form-data` request.
///
/// Such a request has both string [fields], which function as normal form
/// fields, and (potentially streamed) binary [files].
///
/// This request automatically sets the Content-Type header to
/// `multipart/form-data`. This value will override any value set by the user.
///
///     var uri = Uri.https('example.com', 'create');
///     var request = http.MultipartRequest('POST', uri)
///       ..fields['user'] = 'nweiz@google.com'
///       ..files.add(await http.MultipartFile.fromPath(
///           'package', 'build/package.tar.gz',
///           contentType: MediaType('application', 'x-tar')));
///     var response = await request.send();
///     if (response.statusCode == 200) print('Uploaded!');
class MultipartRequest extends BaseRequest {
  /// The total length of the multipart boundaries used when building the
  /// request body.
  ///
  /// According to http://tools.ietf.org/html/rfc1341.html, this can't be longer
  /// than 70.
  static const int _boundaryLength = 70;

  static final Random _random = Random();

  /// The form fields to send for this request.
  final fields = <String, String>{};

  /// The list of files to upload for this request.
  final files = <MultipartFile>[];

  MultipartRequest(String method, Uri url) : super(method, url);

  factory MultipartRequest.fromFormData(
      String method, Uri url, FormData formData) {
    final request = MultipartRequest(method, url);
    request.fields.addAll(formData.fields);
    request.files.addAll(formData.files);
    return request;
  }

  /// The total length of the request body, in bytes.
  ///
  /// This is calculated from [fields] and [files] and cannot be set manually.
  @override
  int get contentLength {
    var length = 0;

    final endOfLineLength = "\r\n".length;

    fields.forEach((name, value) {
      length += '--'.length +
          _boundaryLength +
          endOfLineLength +
          _convertToBytes(_headerForField(name, value)).length +
          _convertToBytes(value).length +
          endOfLineLength;
    });

    for (var file in files) {
      length += '--'.length +
          _boundaryLength +
          endOfLineLength +
          _convertToBytes(_headerForFile(file)).length +
          file.length +
          endOfLineLength;
    }

    return length + '--'.length + _boundaryLength + '--\r\n'.length;
  }

  @override
  set contentLength(int? value) {
    throw UnsupportedError('Cannot set the contentLength property of '
        'multipart requests.');
  }

  /// Freezes all mutable fields and returns a single-subscription [ByteStream]
  /// that will emit the request body.
  @override
  ProgressedBytesStream finalize() {
    // TODO: freeze fields and files
    final boundary = _boundaryString();

    ContentTypeHelper()
        .replace(headers, 'multipart/form-data; boundary=$boundary');
    super.finalize();

    return ProgressedBytesStream(
      contentLength,
      _finalize(boundary),
      shouldReportUploadProgress: shouldReportUploadProgress,
      onUploadProgress: onUploadProgressCallback,
    );
  }

  Stream<Uint8List> _finalize(String boundary) async* {
    const line = [13, 10]; // \r\n
    final separator = _convertToBytes('--$boundary\r\n');
    final close = _convertToBytes('--$boundary--\r\n');

    for (var field in fields.entries) {
      yield separator;
      yield _convertToBytes(_headerForField(field.key, field.value));
      yield _convertToBytes(field.value);
      yield Uint8List.fromList(line);
    }

    for (final file in files) {
      yield separator;
      yield _convertToBytes(_headerForFile(file));
      yield* file.finalize();
      yield Uint8List.fromList(line);
    }
    yield close;
  }

  Uint8List _convertToBytes(String string) =>
      Uint8List.fromList(utf8.encode(string));

  /// Returns the header string for a field.
  ///
  /// The return value is guaranteed to contain only ASCII characters.
  String _headerForField(String name, String value) {
    var header =
        'content-disposition: form-data; name="${_browserEncode(name)}"';
    if (!isPlainAscii(value)) {
      header = '$header\r\n'
          'content-type: text/plain; charset=utf-8\r\n'
          'content-transfer-encoding: binary';
    }
    return '$header\r\n\r\n';
  }

  /// Returns the header string for a file.
  ///
  /// The return value is guaranteed to contain only ASCII characters.
  String _headerForFile(MultipartFile file) {
    var header = 'content-type: ${file.contentType}\r\n'
        'content-disposition: form-data; name="${_browserEncode(file.field)}"';

    if (file.filename != null) {
      header = '$header; filename="${_browserEncode(file.filename!)}"';
    }
    return '$header\r\n\r\n';
  }

  /// Encode [value] in the same way browsers do.
  String _browserEncode(String value) =>
      // http://tools.ietf.org/html/rfc2388 mandates some complex encodings for
      // field names and file names, but in practice user agents seem not to
      // follow this at all. Instead, they URL-encode `\r`, `\n`, and `\r\n` as
      // `\r\n`; URL-encode `"`; and do nothing else (even for `%` or non-ASCII
      // characters). We follow their behavior.
      value.replaceAll(_newlineRegExp, '%0D%0A').replaceAll('"', '%22');

  /// Returns a randomly-generated multipart boundary string
  String _boundaryString() {
    var prefix = 'dart-http-boundary-';
    var list = List<int>.generate(
        _boundaryLength - prefix.length,
        (index) =>
            boundaryCharacters[_random.nextInt(boundaryCharacters.length)],
        growable: false);
    return '$prefix${String.fromCharCodes(list)}';
  }
}

const List<int> boundaryCharacters = <int>[
  43,
  95,
  45,
  46,
  48,
  49,
  50,
  51,
  52,
  53,
  54,
  55,
  56,
  57,
  65,
  66,
  67,
  68,
  69,
  70,
  71,
  72,
  73,
  74,
  75,
  76,
  77,
  78,
  79,
  80,
  81,
  82,
  83,
  84,
  85,
  86,
  87,
  88,
  89,
  90,
  97,
  98,
  99,
  100,
  101,
  102,
  103,
  104,
  105,
  106,
  107,
  108,
  109,
  110,
  111,
  112,
  113,
  114,
  115,
  116,
  117,
  118,
  119,
  120,
  121,
  122
];
