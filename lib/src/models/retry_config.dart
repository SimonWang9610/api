import 'error.dart';

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

typedef WhenException = bool Function(RequestException);
typedef WhenResponseStatus = bool Function(int);
