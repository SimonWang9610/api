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
  static const eventSource = "text/event-stream";

  static MediaType? getMediaType(Map<String, String> headers) {
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

  static void change(MediaType? newType, Map<String, String> headers) {
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

  static void replace(Map<String, String> headers, String header) {
    bool replaced = false;

    for (final field in constants) {
      if (headers.containsKey(field)) {
        headers[field] = header;
        replaced = true;
        break;
      }
    }

    if (!replaced) {
      headers[constants.first] = header;
    }
  }

  static Encoding getEncoding(MediaType? type, Encoding defaultEncoding) {
    if (type == null || !type.parameters.containsKey(charSet)) {
      return defaultEncoding;
    } else {
      return requiredEncodingForCharset(type.parameters[charSet]!);
    }
  }

  static Encoding getEncodingFromHeaders(Map<String, String> headers,
      {Encoding? fallbackEncoding}) {
    final mediaType =
        getMediaType(headers) ?? MediaType("application", 'octet-stream');
    return getEncoding(mediaType, fallbackEncoding ?? latin1);
  }
}
