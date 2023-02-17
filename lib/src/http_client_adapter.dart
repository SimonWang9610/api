import 'dart:async';

import 'response/response_body.dart';
import 'response/response_chunk.dart';
import 'request/base_request.dart';
import 'models/cancel_token.dart';

abstract class HttpClientAdapter {
  Future<ResponseBody> fetch(BaseRequest request, [CancelToken? cancelToken]) =>
      throw UnimplementedError("[$runtimeType client not support fetch");

  void fetchStream(
          BaseRequest request, StreamController<BaseChunk> responseStream,
          [CancelToken? cancelToken]) =>
      throw UnimplementedError("[$runtimeType client not support fetchStream");

  void close({bool force = false});
}
