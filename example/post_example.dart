import 'dart:async';
import 'dart:convert';
import 'package:simple_http_api/simple_http_api.dart';

void main() async {
  // int timestamp = 0;
  // final timer = Timer.periodic(const Duration(seconds: 1), (_) {
  //   timestamp++;
  //   print("seconds passed: $timestamp");
  // });

  // // await _post();
  // await _retryPost();

  // timer.cancel();
  await _post();
}

Future<void> _post() async {
  final headers = {
    "Content-Type": "application/json",
    "Authorization":
        "Bearer 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",
  };

  final url = Uri.parse("https://api.openai.com/v1/chat/completions");

  final data = {
    "model": "gpt-3.5-turbo",
    "messages": [
      {
        "role": "user",
        "content": "what is the difference between you and gpt4",
      }
    ],
    "max_tokens": 2048,
    // "stream": true,
  };

  try {
    final res = await Api.post(
      url,
      headers: headers,
      // cancelToken: TimingToken(Duration(seconds: 2)),
      body: json.encode(data),
      // options: ConnectionOption(
      //   connectionTimeout: Duration(seconds: 1),
      //   sendTimeout: Duration(seconds: 1),
      //   receiveTimeout: Duration(seconds: 3),
      // ),
    );
    print(res);
  } catch (e) {
    print(e);
  }
}

Future<void> _retryPost() async {
  final url = Uri.parse("http://127.0.0.1:8080");

  final data = {
    "hello": "api",
    "delay": 2000,
    "list": [100],
  };

  try {
    final res = await Api.post(
      url,
      headers: {
        "accept": "application/json",
        "content-type": "application/json",
      },
      body: json.encode(data),
      // cancelToken: TimingToken(Duration(seconds: 5)),
      options: ConnectionOption(
        connectionTimeout: Duration(seconds: 1),
        sendTimeout: Duration(seconds: 1),
        // receiveTimeout: Duration(seconds: 2),
      ),
      retryConfig: RetryConfig(
        retryTimeout: Duration(seconds: 3),
        retries: 3,
        // retryWhenException: (e) => e.type != ErrorType.other,
        retryWhenStatus: (code) => code >= 300,
      ),
    );
    print(res);
  } catch (e) {
    print(e);
  }
}
