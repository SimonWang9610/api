import 'error.dart';

// TODO: support retryWhenResponse

/// [retryTimeout] indicates the interval between two requests
/// the first request would be canceled/aborted if no acceptable response is returned during [retryTimeout]
/// and then the next request would be sent
///
/// when a request would stop retrying and return the final result (response/exception)?
/// 1) if an exception is thrown during [retryTimeout],
///   [retryWhenException] and [retries] would determine if continuing retrying
/// 2) if there is a response is returned during [retryTimeout],
///    [retryWhenStatus] and [retries] would determine if continuing retrying
class RetryConfig {
  final Duration retryTimeout;
  final int retries;
  final WhenException? retryWhenException;
  final WhenResponseStatus? retryWhenStatus;

  const RetryConfig({
    required this.retryTimeout,
    required this.retries,
    this.retryWhenException,
    this.retryWhenStatus,
  });
}

typedef WhenException = bool Function(ApiError);
typedef WhenResponseStatus = bool Function(int);
