import 'dart:convert';

import '../request/content_type_helper.dart';
import 'base_response.dart';

class BaseChunk<T extends Object> extends BaseResponse {
  final T chunk;

  const BaseChunk(
    this.chunk, {
    required super.headers,
    required super.isRedirect,
    required super.statusCode,
    super.persistentConnection = true,
    super.contentLength,
    super.statusMessage,
    super.request,
  });

  /// if not found a specific charset in [headers]'s `Content-Type`, it will try fallback to [encoding]
  /// if both cases are not applied, it defaults to [utf8]
  Encoding getEncoding([Encoding? encoding]) {
    final mediaType = ContentTypeHelper.getMediaType(headers);

    return ContentTypeHelper.getEncoding(mediaType, encoding ?? utf8);
  }
}

class WebChunk extends BaseChunk<String> {
  const WebChunk(
    super.chunk, {
    required super.headers,
    required super.isRedirect,
    required super.statusCode,
    super.persistentConnection = true,
    super.contentLength,
    super.statusMessage,
    super.request,
  });
}

class IoChunk extends BaseChunk<List<int>> {
  const IoChunk(
    super.chunk, {
    required super.headers,
    required super.isRedirect,
    required super.statusCode,
    super.persistentConnection = true,
    super.contentLength,
    super.statusMessage,
    super.request,
  });
}
