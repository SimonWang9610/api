import 'clients/event_source_client.dart';
import 'response/response_chunk.dart';
import 'models/cancel_token.dart';
import 'method_enum.dart';

import 'stubs/is_web_stub.dart'
// ignore: uri_does_not_exist
    if (dart.library.html) 'adapters/browser_platform_stub_entry.dart'
// ignore: uri_does_not_exist
    if (dart.library.io) 'adapters/io_platform_stub_entry.dart';

class EventSource {
  final Uri uri;
  final ApiMethod method;
  final Map<String, String> _headers = {};
  final EventSourceClient _client = EventSourceClient();

  bool get isWeb => isWebPlatform();

  EventSource(this.uri, this.method)
      : assert(method == ApiMethod.get || method == ApiMethod.post);

  void setHeaders(Map<String, String> headers) => _headers.addAll(headers);

  Stream<BaseChunk> send({Object? body, CancelToken? cancelToken}) {
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
