import 'dart:async';

import 'package:meta/meta.dart';

import '../adapter_stub.dart'
// ignore: uri_does_not_exist
    if (dart.library.html) '../adapters/browser_stub_entry.dart'
// ignore: uri_does_not_exist
    if (dart.library.io) '../adapters/io_stub_entry.dart';

import '../response/response_body.dart';
import '../response/response_chunk.dart';
import '../request/base_request.dart';
import '../models/cancel_token.dart';
import '../http_client_adapter.dart';

mixin HttpAdapterManager {
  bool get asStream => false;
  bool get withCredentials => false;

  late final HttpClientAdapter _adapter =
      createAdapter(withCredentials: withCredentials, asStream: asStream);

  void close({bool force = false}) {
    _adapter.close(force: force);
  }

  @internal
  @protected
  Future<ResponseBody> sendRequest(BaseRequest request,
          [CancelToken? cancelToken]) =>
      _adapter.fetch(request, cancelToken);

  void sendStreamRequest(
          BaseRequest request, StreamController<ResponseChunk> controller,
          [CancelToken? cancelToken]) =>
      _adapter.fetchStream(request, controller, cancelToken);
}
