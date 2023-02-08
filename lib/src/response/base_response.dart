import 'dart:convert';

import '../request/base_request.dart';
import '../request/content_type_helper.dart';

abstract class BaseResponse {
  final BaseRequest? request;
  final int statusCode;

  final String? statusMessage;

  final int? contentLength;

  final Map<String, String> headers;

  final bool isRedirect;

  final bool persistentConnection;

  BaseResponse({
    required this.isRedirect,
    required this.statusCode,
    required this.headers,
    required this.persistentConnection,
    this.contentLength,
    this.statusMessage,
    this.request,
  });

  Encoding get encoding => ContentTypeHelper().getEncodingFromHeaders(headers);
}
