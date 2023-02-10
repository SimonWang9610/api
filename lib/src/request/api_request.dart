import 'base_request.dart';

import '../models/byte_stream.dart';

class ApiRequest extends BaseRequest with ContentTypeMixin, RequestBodyMixin {
  ApiRequest(String method, Uri url) : super(method, url);

  @override
  ProgressedBytesStream finalize() {
    super.finalize();
    return ProgressedBytesStream(
      contentLength,
      Stream.value(bodyBytes),
      shouldReportUploadProgress: shouldReportUploadProgress,
    );
  }

  @override
  set contentLength(int? value) => throw UnsupportedError(
      'Cannot set the contentLength property for [ApiRequest].');

  @override
  set onProgressCallback(OnProgressCallback? callback) =>
      UnsupportedError('Cannot set [OnProgressCallback] for [ApiRequest].');
}
