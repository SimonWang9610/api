enum ErrorType {
  connectionTimeout("Connection Timeout"),
  sendTimeout("Timeout on sending request"),
  receiveTimeout("Timeout on receiving data"),
  response("Error related to Response"),
  cancel("Request is canceled"),
  other("other"),
  abort("abort");

  final String message;
  const ErrorType(this.message);
}

class RequestException implements Exception {
  final ErrorType type;
  final String? message;
  final String? method;
  final String? url;

  RequestException({
    this.method,
    this.url,
    this.type = ErrorType.other,
    this.message,
  });

  @override
  String toString() {
    return "RequestException(type: $type, message: $message, method: $method, url: $url)";
  }
}
