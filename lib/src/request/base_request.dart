// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http_parser/http_parser.dart';

import '../models/byte_stream.dart';
import '../utils.dart';
import '../models/connection_option.dart';
import 'content_type_helper.dart';

abstract class _FinalizedCheckable {
  bool _finalized = false;
  bool get finalized => _finalized;

  void _checkFinalized() {
    if (!finalized) return;
    throw StateError("Cannot modify a finalized Request");
  }

  void _finalize() {
    if (finalized) throw StateError("Can't finalize a finalized Request.");
    _finalized = true;
  }

  void _assureFinalized() {
    if (!_finalized) {
      throw StateError(
          "Some operations can only execute after a request has been finalized");
    }
  }
}

abstract class BaseRequest
    with _FinalizedCheckable, ConnectionMixin, StreamProgressMixin {
  final String method;
  final Uri url;
  final Map<String, String> headers;

  BaseRequest(String method, this.url)
      : method = _validateMethod(method),
        headers = LinkedHashMap(
            equals: (key1, key2) => key1.toLowerCase() == key2.toLowerCase(),
            hashCode: (key) => key.toLowerCase().hashCode);

  @override
  int? get contentLength => _contentLength;
  int? _contentLength;

  set contentLength(int? value) {
    if (value != null && value < 0) {
      throw ArgumentError('Invalid content length $value.');
    }
    _checkFinalized();
    _contentLength = value;
  }

  ProgressedBytesStream finalize() {
    _finalize();
    return ProgressedBytesStream.empty();
  }

  static final _tokenRE = RegExp(r"^[\w!#%&'*+\-.^`|~]+$");
  static String _validateMethod(String method) {
    if (!_tokenRE.hasMatch(method)) {
      throw ArgumentError.value(method, 'method', 'Not a valid method');
    }
    return method;
  }
}

// ignore: library_private_types_in_public_api
mixin ConnectionMixin on _FinalizedCheckable {
  ConnectionOption _options = ConnectionOption.defaultOption;

  ConnectionOption get options => _options;
  set options(ConnectionOption value) {
    _checkFinalized();
    _options = value;
  }

  bool get persistentConnection => _options.persistentConnection;
  set persistentConnection(bool value) {
    _checkFinalized();
    _options = _options.copyWith(persistentConnection: value);
  }

  bool get followRedirects => _options.followRedirects;
  set followRedirects(bool value) {
    _checkFinalized();
    _options = _options.copyWith(followRedirects: value);
  }

  int get maxRedirects => _options.maxDirects;
  set maxRedirects(int value) {
    _checkFinalized();
    _options = _options.copyWith(maxDirects: value);
  }

  Duration? get sendTimeout => _options.sendTimeout;
  set sendTimeout(Duration? value) {
    _checkFinalized();
    _options = _options.copyWith(sendTimeout: value);
  }

  Duration? get connectionTimeout => _options.connectionTimeout;
  set connectionTimeout(Duration? value) {
    _checkFinalized();
    _options = _options.copyWith(connectionTimeout: value);
  }

  Duration? get receiveTimeout => _options.receiveTimeout;
  set receiveTimeout(Duration? value) {
    _checkFinalized();
    _options = _options.copyWith(receiveTimeout: value);
  }

  Future? _cancelToken;
  Future? get cancelToken => _cancelToken;
  set cancelToken(Future? value) {
    _checkFinalized();
    _cancelToken = value;
  }
}

// ignore: library_private_types_in_public_api
mixin ContentTypeMixin on _FinalizedCheckable {
  Map<String, String> get headers;

  MediaType? get _contentType => ContentTypeHelper.getMediaType(headers);

  set _contentType(MediaType? value) {
    ContentTypeHelper.change(value, headers);
  }

  Encoding _defaultEncoding = utf8;

  Encoding get encoding =>
      ContentTypeHelper.getEncoding(_contentType, _defaultEncoding);

  set encoding(Encoding value) {
    _checkFinalized();
    _defaultEncoding = value;
    var contentType = _contentType;
    if (contentType == null) return;
    _contentType =
        contentType.change(parameters: {ContentTypeHelper.charSet: value.name});
  }
}

// ignore: library_private_types_in_public_api
mixin RequestBodyMixin on _FinalizedCheckable, ContentTypeMixin {
  Uint8List _bodyBytes = Uint8List(0);

  Uint8List get bodyBytes => _bodyBytes;
  int get contentLength => bodyBytes.length;

  set bodyBytes(List<int> value) {
    _checkFinalized();
    _bodyBytes = toUint8List(value);
  }

  String get body => encoding.decode(bodyBytes);
  set body(String value) {
    bodyBytes = encoding.encode(value);
    var contentType = _contentType;
    if (contentType == null) {
      _contentType = MediaType('text', 'plain', {'charset': encoding.name});
    } else if (!contentType.parameters.containsKey('charset')) {
      _contentType = contentType.change(parameters: {'charset': encoding.name});
    }
  }

  Map<String, String> get bodyFields {
    var contentType = _contentType;
    if (contentType == null ||
        contentType.mimeType != 'application/x-www-form-urlencoded') {
      throw StateError('Cannot access the body fields of a Request without '
          'content-type "application/x-www-form-urlencoded".');
    }

    return Uri.splitQueryString(body, encoding: encoding);
  }

  set bodyFields(Map<String, String> fields) {
    var contentType = _contentType;
    if (contentType == null) {
      _contentType = MediaType('application', 'x-www-form-urlencoded');
    } else if (contentType.mimeType != 'application/x-www-form-urlencoded') {
      throw StateError('Cannot set the body fields of a Request with '
          'content-type "${contentType.mimeType}".');
    }

    body = mapToQuery(fields, encoding: encoding);
  }
}

// ignore: library_private_types_in_public_api
mixin StreamProgressMixin on _FinalizedCheckable {
  int? get contentLength;

  OnProgressCallback? _onUploadProgressCallback;
  OnProgressCallback? get onUploadProgressCallback => _onUploadProgressCallback;
  set onUploadProgressCallback(OnProgressCallback? callback) {
    _checkFinalized();
    _onUploadProgressCallback = callback;
  }

  bool get shouldReportUploadProgress {
    _assureFinalized();
    return contentLength != null &&
        contentLength! > 0 &&
        _onUploadProgressCallback != null;
  }
}
