import 'response/response_body.dart';
import 'request/base_request.dart';

abstract class HttpClientAdapter {
  Future<ResponseBody> fetch(BaseRequest request);

  void close({bool force = false});
}
