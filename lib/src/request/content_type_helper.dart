import 'dart:convert';

import 'package:http_parser/http_parser.dart';

import '../utils.dart';

class ContentTypeHelper {
  static const List<String> constants = [
    "content-type",
    "ContentType",
    "Content-Type"
  ];

  static const charSet = "charset";

  const ContentTypeHelper._();

  static const _instance = ContentTypeHelper._();

  factory ContentTypeHelper() => _instance;

  MediaType? getMediaType(Map<String, String> headers) {
    String? contentType;

    for (final type in constants) {
      contentType ??= headers[type];
      if (contentType != null) break;
    }

    if (contentType != null) {
      return MediaType.parse(contentType);
    } else {
      return null;
    }
  }

  void change(MediaType? newType, Map<String, String> headers) {
    if (newType == null) {
      for (final type in constants) {
        headers.remove(type);
      }
    } else {
      bool changed = false;

      for (final type in constants) {
        if (headers.containsKey(type)) {
          headers[type] = newType.toString();
          changed = true;
          break;
        }
      }

      if (!changed) {
        headers[constants.first] = newType.toString();
      }
    }
  }

  Encoding getEncoding(MediaType? type, Encoding defaultEncoding) {
    if (type == null || !type.parameters.containsKey(charSet)) {
      return defaultEncoding;
    } else {
      return requiredEncodingForCharset(type.parameters[charSet]!);
    }
  }

  Encoding getEncodingFromHeaders(Map<String, String> headers) {
    final mediaType =
        getMediaType(headers) ?? MediaType("application", 'octet-stream');
    return getEncoding(mediaType, latin1);
  }
}
