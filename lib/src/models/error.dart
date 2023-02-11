enum ErrorType {
  connectionTimeout("Connection Timeout"),
  sendTimeout("Timeout on sending request"),
  receiveTimeout("Timeout on receiving data"),
  response("Error related to Response"),
  cancel("Request is canceled/ or aborted"),
  other("other");
  // abort("abort");

  final String message;
  const ErrorType(this.message);
}

class ApiError implements Exception {
  final ErrorType type;
  final String? message;
  final String? method;
  final String? url;

  ApiError({
    this.method,
    this.url,
    this.type = ErrorType.other,
    this.message,
  });

  @override
  String toString() {
    return "ApiError(type: $type, message: $message, method: $method, url: $url)";
  }
}
