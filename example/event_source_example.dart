import 'dart:convert';
import 'package:simple_http_api/simple_http_api.dart';

import 'key.dart';

void main() async {
  final headers = {
    "Content-Type": "application/json",
    "Authorization": "Bearer $apiKey",
  };

  final url = Uri.parse("https://api.openai.com/v1/chat/completions");

  final template = 'write a chinese poem. do not translate.';

  final data = {
    "model": "gpt-3.5-turbo",
    "messages": [
      {
        "role": "user",
        "content": template,
      }
    ],
    "max_tokens": 1024,
    "stream": true,
  };

  final result = await Api.post(
    url,
    headers: headers,
    body: json.encode(data),
    responseEncoding: utf8,
  );
  print(result.encoding);

  print(result.body);

  // final eventSource = EventSource(url, ApiMethod.post);
  // eventSource.setHeaders(headers);

  // // final cancelToken = TimingToken(Duration(seconds: 5));
  // final stream = eventSource.send(body: json.encode(data));
  // // final stream = eventSource.send(cancelToken: cancelToken);

  // stream.listen(
  //   (event) {
  //     if (eventSource.isWeb) {
  //       print(event.chunk as String);
  //     } else {
  //       final encoding = event.getEncoding();

  //       print(encoding.decode(event.chunk as List<int>));
  //     }
  //   },
  //   onError: (err) => print(err),
  //   onDone: eventSource.close,
  // );
}
