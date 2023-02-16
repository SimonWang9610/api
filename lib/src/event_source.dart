import 'clients/event_source_client.dart';
import 'response/response_chunk.dart';
import 'models/cancel_token.dart';
import 'method_enum.dart';

class EventSource {
  final Uri uri;
  final ApiMethod method;
  final Map<String, String> _headers = {};
  final EventSourceClient _client = EventSourceClient();

  EventSource(this.uri, this.method)
      : assert(method == ApiMethod.get || method == ApiMethod.post);

  void setHeaders(Map<String, String> headers) => _headers.addAll(headers);

  Stream<ResponseChunk> send([Object? body, CancelToken? cancelToken]) {
    switch (method) {
      case ApiMethod.get:
        return _client.get(uri, headers: _headers, cancelToken: cancelToken);
      case ApiMethod.post:
        return _client.post(uri,
            headers: _headers, body: body, cancelToken: cancelToken);
      default:
        throw UnimplementedError("$method not support for [EventSource]");
    }
  }

  void close({bool force = false}) {
    _client.close(force: force);
  }
}
