import 'dart:convert';

import 'package:simple_http_api/simple_http_api.dart';

void main() async {
  await eventSourceExample();
  await getExample();
  await getRetryExample();
  await postExample();
  await postRetryExample();
  await uploadExample();
}

Future<void> eventSourceExample() async {
  final headers = {
    "Content-Type": "application/json",
    "Authorization": "Bearer <token>",
  };

  final url = Uri.parse("https://api.openai.com/v1/completions");

  final data = {
    "model": "text-davinci-003",
    "prompt": "give 5 words",
    "max_tokens": 256,
    "stream": true,
  };

  final eventSource = EventSource(url, ApiMethod.get);
  eventSource.setHeaders(headers);

  final cancelToken = TimingToken(Duration(seconds: 5));
  final stream =
      eventSource.send(body: json.encode(data), cancelToken: cancelToken);
  // final stream = eventSource.send(cancelToken: cancelToken);

  stream.listen(
    (event) {
      if (eventSource.isWeb) {
        print(event.chunk as String);
      } else {
        final encoding = event.getEncoding();

        print(encoding.decode(event.chunk as List<int>));
      }
    },
    onError: (err) => print(err),
    onDone: eventSource.close,
  );
}

Future<void> getRetryExample([int? delayMs]) async {
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

Future<void> getExample([int? delayMs]) async {
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

Future<void> postExample() async {
  final url = Uri.parse("http://127.0.0.1:8080");

  final data = {
    "hello": "api",
    // "delay": 2000,
    "list": [100],
  };

  try {
    final res = await Api.post(
      url,
      headers: {
        // "accept": "application/json",
        "content-type": "application/json",
      },
      // cancelToken: TimingToken(Duration(seconds: 2)),
      body: json.encode(data),
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

Future<void> postRetryExample() async {
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

Future<void> uploadExample() async {
  final url = Uri.parse("http://127.0.0.1:8080/upload/multi");
  final file1 =
      await FormData.fileFromPath("./assets/demo.mp4", field: "multi");

  final file2 =
      await FormData.fileFromPath("./assets/demo.png", field: "multi");

  final formData = FormData();

  formData.addFile(file1);
  formData.addFile(file2);

  formData.addFields({"upload": "test"});

  try {
    final res = await Api.upload(
      url,
      formData,
      cancelToken: TimingToken(Duration(seconds: 3)),
      headers: {
        "content-type": "application/json",
      },
    );
    print(res);
  } catch (e) {
    print("e");
  }
}
