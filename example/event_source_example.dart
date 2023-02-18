import 'dart:async';
import 'dart:convert';
import 'package:extended_http/extended_http.dart';

void main() async {
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
