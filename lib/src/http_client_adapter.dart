import 'response/response_body.dart';
import 'request/base_request.dart';
import 'models/cancel_token.dart';

abstract class HttpClientAdapter {
  Future<ResponseBody> fetch(BaseRequest request, [CancelToken? cancelToken]);

  void close({bool force = false});
}
