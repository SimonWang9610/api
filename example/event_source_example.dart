import 'dart:convert';
import 'package:simple_http_api/simple_http_api.dart';

void main() async {
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
    "stream": true,
  };

  final eventSource = EventSource(url, ApiMethod.post);
  eventSource.setHeaders(headers);

  // final cancelToken = TimingToken(Duration(seconds: 5));
  final stream = eventSource.send(body: json.encode(data));
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
