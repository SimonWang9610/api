import 'dart:convert';

import 'response/api_response.dart';
import 'models/models.dart';
import 'multipart/form_data.dart';
import 'method_enum.dart';
import 'client.dart';
import 'parallel/parallel.dart';
import 'parallel/converter.dart';

typedef ApiMethodWrapper = Future<ApiResponse> Function(Client);

Future<ApiResponse> _withApi(ApiMethodWrapper fn,
    {RetryConfig? retryConfig, bool forUpload = false}) async {
  final api = forUpload ? Client.multipart() : Client.single(retryConfig);

  try {
    return await fn(api);
  } finally {
    api.close();
  }
}

Future<ApiResponse> _isolateWrapper(
    Future<ApiResponse> Function() apiExecutor) async {
  return useIsolate<ApiResponse, String>(
    "",
    (_) => apiExecutor(),
    toJson: apiResponseToJson,
    fromJson: jsonToApiResponse,
  );
}

class Api {
  static Future<ApiResponse> get(
    Uri url, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
    ConnectionOption? options,
    RetryConfig? retryConfig,
    Encoding? responseEncoding,
  }) =>
      _withApi(
        (api) => api.get(
          url,
          headers: headers,
          cancelToken: cancelToken,
          options: options,
          responseEncoding: responseEncoding,
        ),
        retryConfig: retryConfig,
      );

  static Future<ApiResponse> head(
    Uri url, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
    ConnectionOption? options,
    RetryConfig? retryConfig,
  }) =>
      _withApi(
        (api) => api.head(
          url,
          headers: headers,
          cancelToken: cancelToken,
          options: options,
        ),
        retryConfig: retryConfig,
      );

  static Future<ApiResponse> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CancelToken? cancelToken,
    ConnectionOption? options,
    RetryConfig? retryConfig,
    Encoding? responseEncoding,
  }) =>
      _withApi(
        (api) => api.post(
          url,
          headers: headers,
          body: body,
          encoding: encoding,
          cancelToken: cancelToken,
          options: options,
          responseEncoding: responseEncoding,
        ),
        retryConfig: retryConfig,
      );

  static Future<ApiResponse> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CancelToken? cancelToken,
    ConnectionOption? options,
    RetryConfig? retryConfig,
    Encoding? responseEncoding,
  }) =>
      _withApi(
        (api) => api.put(
          url,
          headers: headers,
          body: body,
          encoding: encoding,
          cancelToken: cancelToken,
          options: options,
          responseEncoding: responseEncoding,
        ),
        retryConfig: retryConfig,
      );

  static Future<ApiResponse> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CancelToken? cancelToken,
    ConnectionOption? options,
    RetryConfig? retryConfig,
    Encoding? responseEncoding,
  }) =>
      _withApi(
        (api) => api.patch(
          url,
          headers: headers,
          body: body,
          encoding: encoding,
          cancelToken: cancelToken,
          options: options,
          responseEncoding: responseEncoding,
        ),
        retryConfig: retryConfig,
      );

  static Future<ApiResponse> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CancelToken? cancelToken,
    ConnectionOption? options,
    RetryConfig? retryConfig,
    Encoding? responseEncoding,
  }) =>
      _withApi(
        (api) => api.delete(
          url,
          headers: headers,
          body: body,
          encoding: encoding,
          cancelToken: cancelToken,
          options: options,
          responseEncoding: responseEncoding,
        ),
        retryConfig: retryConfig,
      );

  static Future<ApiResponse> upload(
    Uri url,
    FormData formData, {
    ApiMethod method = ApiMethod.post,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    ConnectionOption? options,
    OnProgressCallback? onUploadProgress,
    Encoding? responseEncoding,
    bool useIsolate = false,
  }) {
    if (useIsolate) {
      return _isolateWrapper(
        () => _withApi(
          (api) => api.upload(
            url,
            method: method,
            formData,
            headers: headers,
            cancelToken: cancelToken,
            options: options,
            onUploadProgress: onUploadProgress,
            responseEncoding: responseEncoding,
          ),
          forUpload: true,
        ),
      );
    } else {
      return _withApi(
        (api) => api.upload(
          url,
          method: method,
          formData,
          headers: headers,
          cancelToken: cancelToken,
          options: options,
          onUploadProgress: onUploadProgress,
          responseEncoding: responseEncoding,
        ),
        forUpload: true,
      );
    }
  }
}
