import 'dart:async';
import 'package:meta/meta.dart';

import '../models/models.dart';
import '../multipart/form_data.dart';
import '../request/multi_part_request.dart';
import '../response/api_response.dart';
import '../method_enum.dart';
import '../utils.dart';

import '../client.dart';
import 'adapter_mixin.dart';

class MultipartClient extends Client with HttpAdapterManager {
  @override
  Future<ApiResponse> upload(
    Uri url,
    FormData formData, {
    ApiMethod method = ApiMethod.post,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    ConnectionOption? options,
    OnProgressCallback? onUploadProgress,
  }) =>
      create(
        method,
        url,
        headers,
        formData: formData,
        cancelToken: cancelToken,
        options: options,
        onUploadProgress: onUploadProgress,
      );

  @internal
  @protected
  Future<ApiResponse> create(
    ApiMethod method,
    Uri url,
    Map<String, String>? headers, {
    required FormData formData,
    CancelToken? cancelToken,
    ConnectionOption? options,
    OnProgressCallback? onUploadProgress,
  }) async {
    final request = _createMultipartRequest(
      method,
      url,
      formData,
      headers: headers,
      onUploadProgress: onUploadProgress,
    );

    if (options != null) {
      request.options = options;
    }

    request.cancelToken = cancelToken?.token;

    late ApiResponse res;
    try {
      final resBody = await sendRequest(request, cancelToken);
      res = await ApiResponse.fromStream(resBody);
    } catch (e) {
      throw assureApiError(e);
    } finally {
      cancelToken?.expire();
    }

    return res;
  }

  MultipartRequest _createMultipartRequest(
    ApiMethod method,
    Uri url,
    FormData data, {
    Map<String, String>? headers,
    OnProgressCallback? onUploadProgress,
  }) {
    final request = MultipartRequest.fromFormData(method.value, url, data)
      ..onUploadProgressCallback = onUploadProgress;

    if (headers != null) request.headers.addAll(headers);
    return request;
  }
}
