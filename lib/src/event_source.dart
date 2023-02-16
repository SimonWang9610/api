import 'clients/event_source_client.dart';
import 'response/response_chunk.dart';
import 'method_enum.dart';

class EventSource {
  final Uri uri;
  final ApiMethod method;
  final Map<String, String> _headers = {};
  final EventSourceClient _client = EventSourceClient();

  EventSource(this.uri, this.method)
      : assert(method == ApiMethod.get || method == ApiMethod.post);

  void setHeaders(Map<String, String> headers) => _headers.addAll(headers);

  Stream<ResponseChunk> send([Object? body]) {
    switch (method) {
      case ApiMethod.get:
        return _client.get(uri, headers: _headers);
      case ApiMethod.post:
        return _client.post(uri, headers: _headers, body: body);
      default:
        throw UnimplementedError("$method not support for [EventSource]");
    }
  }
}
