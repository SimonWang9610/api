import 'dart:convert';
import 'dart:typed_data';

import '../models/byte_stream.dart';
import 'response_body.dart';
import 'base_response.dart';

class ApiResponse extends BaseResponse {
  final Uint8List bodyBytes;

  String get body => encoding.decode(bodyBytes);

  ApiResponse(
    this.bodyBytes, {
    required super.headers,
    required super.isRedirect,
    required super.persistentConnection,
    required super.statusCode,
    super.contentLength,
    super.statusMessage,
    super.request,
    super.defaultEncoding,
  });

  static Future<ApiResponse> fromStream(
    ResponseBody resBody, {
    Encoding? defaultEncoding,
  }) async {
    final bytes = await resBody.stream.toBytes();
    return ApiResponse(
      bytes,
      headers: resBody.headers,
      statusCode: resBody.statusCode,
      isRedirect: resBody.isRedirect,
      persistentConnection: resBody.persistentConnection,
      request: resBody.request,
      contentLength: resBody.contentLength,
      statusMessage: resBody.statusMessage,
      defaultEncoding: defaultEncoding,
    );
  }

  @override
  String toString() {
    return "ApiResponse(status: $statusCode, headers: $headers, isRedirect: $isRedirect, body: $body, length: $contentLength)";
  }
}
