import 'dart:async';
import 'dart:convert';
import 'package:meta/meta.dart';

import '../models/cancel_token.dart';
import '../request/api_request.dart';
import '../response/response_chunk.dart';
import '../method_enum.dart';

import 'adapter_mixin.dart';

class EventSourceClient with HttpAdapterManager {
  @override
  bool get asStream => true;

  final StreamController<ResponseChunk> _controller = StreamController();

  Stream<ResponseChunk> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    CancelToken? cancelToken,
  }) {
    final request =
        createApiRequest(ApiMethod.post, url, headers: headers, body: body);

    sendStreamRequest(request, _controller, cancelToken);
    return _controller.stream;
  }

  Stream<ResponseChunk> get(
    Uri url, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) {
    final request = createApiRequest(ApiMethod.post, url, headers: headers);

    sendStreamRequest(request, _controller, cancelToken);
    return _controller.stream;
  }

  ApiRequest createApiRequest(
    ApiMethod method,
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    final request = ApiRequest(method.value, url);

    if (headers != null) request.headers.addAll(headers);

    if (encoding != null) request.encoding = encoding;
    if (body != null) {
      if (body is String) {
        request.body = body;
      } else if (body is List) {
        request.bodyBytes = body.cast<int>();
      } else if (body is Map) {
        request.bodyFields = body.cast<String, String>();
      } else {
        throw ArgumentError('Invalid request body "$body".');
      }
    }
    return request;
  }

  @override
  void close({bool force = false}) {
    if (!_controller.isClosed) {
      _controller.close();
    }
    super.close(force: force);
  }
}
