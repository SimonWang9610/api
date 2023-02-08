import 'base_request.dart';

import '../models/byte_stream.dart';

class ApiRequest extends BaseRequest with ContentTypeMixin, RequestBodyMixin {
  ApiRequest(String method, Uri url) : super(method, url);

  @override
  ByteStream finalize() {
    super.finalize();
    return Stream.value(bodyBytes);
  }

  @override
  set contentLength(int? value) => throw UnsupportedError(
      'Cannot set the contentLength property for [ApiRequest].');
}
