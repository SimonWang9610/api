import 'dart:async';
import 'dart:convert';

import '../models/cancel_token.dart';
import '../request/api_request.dart';
import '../response/response_chunk.dart';
import '../method_enum.dart';

import 'adapter_mixin.dart';

/// used to receive response data and stream them to users when each data chunk is received
/// once [ApiError] is added into [_controller], the stream would be closed.
/// no matter the error is reported either by the underlying platforms or due to the validation of the [ConnectionOption]
/// the associated request would be canceled/aborted
class EventSourceClient with HttpAdapterManager {
  @override
  bool get asStream => true;

  final StreamController<BaseChunk> _controller = StreamController();

  Stream<BaseChunk> post(
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

  Stream<BaseChunk> get(
    Uri url, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) {
    final request = createApiRequest(ApiMethod.get, url, headers: headers);

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
