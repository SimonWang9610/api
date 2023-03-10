import 'dart:async';

import '../stubs/adapter_stub.dart'
// ignore: uri_does_not_exist
    if (dart.library.html) '../adapters/browser_stub_entry.dart'
// ignore: uri_does_not_exist
    if (dart.library.io) '../adapters/io_stub_entry.dart';

import '../response/response_body.dart';
import '../response/response_chunk.dart';
import '../request/base_request.dart';
import '../models/cancel_token.dart';
import '../http_client_adapter.dart';

/// all [Client] should mixin [HttpAdapterManager] so as to use [sendRequest] and [sendStreamRequest]
mixin HttpAdapterManager {
  /// if true, [sendStreamRequest] would be used, and the response data would be streamed when data chunk is arrived
  /// otherwise, [sendRequest] would be used, and the response data would not be returned until all data chunks are collected
  bool get asStream => false;
  bool get withCredentials => false;

  /// create [HttpClientAdapter], avoiding exposing the underlying implementations
  /// so that [Client] could focus on constructing [BaseRequest] and then submitting request to [_adapter]
  /// by invoking [sendRequest] or [sendStreamRequest]
  late final HttpClientAdapter _adapter =
      createAdapter(withCredentials: withCredentials, asStream: asStream);

  void close({bool force = false}) {
    _adapter.close(force: force);
  }

  Future<ResponseBody> sendRequest(BaseRequest request,
          [CancelToken? cancelToken]) =>
      _adapter.fetch(request, cancelToken);

  void sendStreamRequest(
          BaseRequest request, StreamController<BaseChunk> controller,
          [CancelToken? cancelToken]) =>
      _adapter.fetchStream(request, controller, cancelToken);
}
