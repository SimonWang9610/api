import 'package:meta/meta.dart';

import '../adapter_stub.dart'
// ignore: uri_does_not_exist
    if (dart.library.html) '../adapters/browser_adapter.dart'
// ignore: uri_does_not_exist
    if (dart.library.io) '../adapters/io_adapter.dart';

import '../response/response_body.dart';
import '../request/base_request.dart';
import '../models/cancel_token.dart';
import '../http_client_adapter.dart';
import '../client.dart';

mixin HttpAdapterManager on Client {
  final HttpClientAdapter _adapter = createAdapter();

  // HttpClientAdapter get adapter => _adapter;

  @override
  void close({bool force = false}) {
    _adapter.close(force: force);
  }

  @internal
  @protected
  Future<ResponseBody> sendRequest(BaseRequest request,
          [CancelToken? cancelToken]) =>
      _adapter.fetch(request, cancelToken);
}
