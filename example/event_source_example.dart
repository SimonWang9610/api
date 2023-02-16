import 'dart:convert';
import 'package:api/api.dart';

void main() async {
  final headers = {
    "Content-Type": "application/json",
    "Authorization":
        "Bearer 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",
  };

  final url = Uri.parse("https://api.openai.com/v1/completions");

  final data = {
    "model": "text-davinci-003",
    "prompt": "give 5 words",
    "max_tokens": 256,
    "stream": true,
  };

  final eventSource = EventSource(url, ApiMethod.post);
  eventSource.setHeaders(headers);

  final stream = eventSource.send(json.encode(data));

  stream.listen(
    (event) {
      print(event.chunk);
    },
    onError: (err) => print(err),
  );
}
