import 'dart:convert';

import '../request/content_type_helper.dart';
import '../request/base_request.dart';
import '../models/byte_stream.dart';

class ResponseBody {
  final ByteStream stream;
  final int statusCode;
  final int? contentLength;
  final Map<String, String> headers;
  final bool isRedirect;
  final String? statusMessage;
  final bool persistentConnection;
  final BaseRequest request;
  const ResponseBody({
    required this.request,
    required this.stream,
    required this.statusCode,
    required this.headers,
    required this.isRedirect,
    this.contentLength,
    this.statusMessage,
    this.persistentConnection = true,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'statusCode': statusCode,
      'contentLength': contentLength,
      'headers': headers,
      'isRedirect': isRedirect,
      'statusMessage': statusMessage,
    };
  }

  String toJson() => json.encode(toMap());

  Encoding get encoding => ContentTypeHelper().getEncodingFromHeaders(headers);
}
