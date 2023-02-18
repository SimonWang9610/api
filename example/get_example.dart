import 'dart:async';
import 'package:simple_http_api/simple_http_api.dart';

void main() async {
  int timestamp = 0;
  final timer = Timer.periodic(const Duration(seconds: 1), (_) {
    timestamp++;
    print("seconds passed: $timestamp");
  });

  // await _get(4000);
  await _retryGet(4000);

  timer.cancel();
}

Future<void> _get([int? delayMs]) async {
  final delay = delayMs != null && delayMs > 0 ? "?delay=$delayMs" : "";

  final url = Uri.parse("http://127.0.0.1:8080$delay");

  try {
    final res = await Api.get(
      url,
      headers: {"accept": "application/json"},
      // cancelToken: TimingToken(Duration(seconds: 2)),
      options: ConnectionOption(
        connectionTimeout: Duration(seconds: 1),
        sendTimeout: Duration(seconds: 1),
        receiveTimeout: Duration(seconds: 3),
      ),
    );
    print(res);
  } catch (e) {
    print(e);
  }
}

Future<void> _retryGet([int? delayMs]) async {
  final delay = delayMs != null && delayMs > 0 ? "?delay=$delayMs" : "";

  final url = Uri.parse("http://127.0.0.1:8080$delay");

  try {
    final res = await Api.get(
      url,
      // headers: {"accept": "application/json"},
      // cancelToken: TimingToken(Duration(seconds: 3)),
      options: ConnectionOption(
        connectionTimeout: Duration(seconds: 1),
        sendTimeout: Duration(seconds: 1),
        receiveTimeout: Duration(seconds: 2),
      ),
      retryConfig: RetryConfig(
        retryTimeout: Duration(seconds: 5),
        retries: 3,
        retryWhenException: (e) => e.type != ErrorType.other,
        retryWhenStatus: (code) => code >= 300,
      ),
    );
    print(res);
  } catch (e) {
    print(e);
  }
}
