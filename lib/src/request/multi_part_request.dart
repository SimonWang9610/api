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

/// The finalized String output of [MultipartRequest] would follow this format
/// content-length: [length]
/// content-type: multipart/form-data; boundary=[_generateBoundaryString]
/// --[_generateBoundaryString]
/// <header area> for one field of [fields]
///
/// <field value>
/// --[_generateBoundaryString]
/// <header area> for one field of [fields]
///
/// <field value>
/// <...>
/// --[_generateBoundaryString]
/// <header area> for one file of [files]
///
/// <file data>
class MultipartRequest extends BaseRequest {
  /// The total length of the multipart boundaries used when building the
  /// request body.
  ///
  /// According to https://www.rfc-editor.org/rfc/rfc2046#section-5.1.1, it should be in [1, 70]
  static const int _boundaryLength = 30;
  static const String _boundaryPrefix = "simple-api-";
  static const String _endOfLine = "\r\n";

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
    int length = 0;

    fields.forEach(
      (name, value) {
        length += '--'.length +
            _boundaryLength +
            _endOfLine.length +
            _convertToBytes(_headerForField(name, value)).length +
            _convertToBytes(value).length +
            _endOfLine.length;
      },
    );

    for (var file in files) {
      length += '--'.length +
          _boundaryLength +
          _endOfLine.length +
          _convertToBytes(_headerForFile(file)).length +
          file.length +
          _endOfLine.length;
    }

    return length +
        '--'.length +
        _boundaryLength +
        '--'.length +
        _endOfLine.length;
  }

  @override
  set contentLength(int? value) {
    throw UnsupportedError('Cannot set the contentLength property of '
        'multipart requests.');
  }

  /// According to https://www.rfc-editor.org/rfc/rfc7578#section-4.3, `multipart/mixed` has been deprecated
  /// multiple files MUST be sent by supplying each file in a separate part but all with the same
  /// "name" parameter.
  @override
  ProgressedBytesStream finalize() {
    final boundary = _generateBoundaryString();

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
    final separator = _convertToBytes('--$boundary$_endOfLine');
    final endOfLineBytes = Uint8List.fromList([13, 10]);

    for (var field in fields.entries) {
      yield separator;
      yield _convertToBytes(_headerForField(field.key, field.value));
      yield _convertToBytes(field.value);
      yield endOfLineBytes;
    }

    for (final file in files) {
      yield separator;
      yield _convertToBytes(_headerForFile(file));
      yield* file.finalize();
      yield endOfLineBytes;
    }
    yield _convertToBytes('--$boundary--$_endOfLine');
  }

  Uint8List _convertToBytes(String string) =>
      Uint8List.fromList(utf8.encode(string));

  /// Returns the header string for a field.
  ///
  /// The return value is guaranteed to contain only ASCII characters.
  String _headerForField(String key, String value) {
    String header =
        'content-disposition: form-data; name="${_browserEncode(key)}"';

    if (!isPlainAscii(value)) {
      header = '$header$_endOfLine'
          'content-type: text/plain; charset=utf-8$_endOfLine'
          'content-transfer-encoding: binary';
    }
    return '$header$_endOfLine$_endOfLine';
  }

  /// Returns the header string for a file.
  ///
  /// The return value is guaranteed to contain only ASCII characters.
  String _headerForFile(MultipartFile file) {
    var header = 'content-type: ${file.contentType}$_endOfLine'
        'content-disposition: form-data; name="${_browserEncode(file.field)}"';

    if (file.filename != null) {
      header = '$header; filename="${_browserEncode(file.filename!)}"';
    }
    return '$header$_endOfLine$_endOfLine';
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
  String _generateBoundaryString() {
    final list = List<int>.generate(
        _boundaryLength - _boundaryPrefix.length,
        (index) =>
            boundaryCharacters[_random.nextInt(boundaryCharacters.length)],
        growable: false);
    return '$_boundaryPrefix${String.fromCharCodes(list)}';
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
