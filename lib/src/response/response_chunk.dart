import '../request/base_request.dart';

class ResponseChunk {
  final String chunk;
  final int statusCode;
  final int? contentLength;
  final Map<String, String> headers;
  final bool isRedirect;
  final String? statusMessage;
  final bool persistentConnection;
  final BaseRequest request;

  const ResponseChunk({
    required this.request,
    required this.chunk,
    required this.statusCode,
    required this.headers,
    required this.isRedirect,
    this.contentLength,
    this.statusMessage,
    this.persistentConnection = true,
  });
}
