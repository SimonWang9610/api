import 'dart:convert';

import 'response/api_response.dart';
import 'models/cancel_token.dart';
import 'models/connection_option.dart';
import 'api_base.dart';

typedef ApiMethodWrapper = Future<ApiResponse> Function(Client);

Future<ApiResponse> _withApi(ApiMethodWrapper fn,
    [RetryConfig? retryConfig]) async {
  final api = retryConfig != null ? RetryClient(retryConfig) : Client();

  try {
    return await fn(api);
  } finally {
    api.close();
  }
}

class Api {
  static Future<ApiResponse> get(
    Uri url, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
    ConnectionOption? options,
    RetryConfig? retryConfig,
  }) =>
      _withApi(
        (api) => api.get(
          url,
          headers: headers,
          cancelToken: cancelToken,
          options: options,
        ),
        retryConfig,
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
        retryConfig,
      );

  static Future<ApiResponse> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CancelToken? cancelToken,
    ConnectionOption? options,
    RetryConfig? retryConfig,
  }) =>
      _withApi(
        (api) => api.post(
          url,
          headers: headers,
          body: body,
          encoding: encoding,
          cancelToken: cancelToken,
          options: options,
        ),
        retryConfig,
      );

  static Future<ApiResponse> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CancelToken? cancelToken,
    ConnectionOption? options,
    RetryConfig? retryConfig,
  }) =>
      _withApi(
        (api) => api.put(
          url,
          headers: headers,
          body: body,
          encoding: encoding,
          cancelToken: cancelToken,
          options: options,
        ),
        retryConfig,
      );

  static Future<ApiResponse> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CancelToken? cancelToken,
    ConnectionOption? options,
    RetryConfig? retryConfig,
  }) =>
      _withApi(
        (api) => api.patch(
          url,
          headers: headers,
          body: body,
          encoding: encoding,
          cancelToken: cancelToken,
          options: options,
        ),
        retryConfig,
      );

  static Future<ApiResponse> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CancelToken? cancelToken,
    ConnectionOption? options,
    RetryConfig? retryConfig,
  }) =>
      _withApi(
        (api) => api.delete(
          url,
          headers: headers,
          body: body,
          encoding: encoding,
          cancelToken: cancelToken,
          options: options,
        ),
        retryConfig,
      );
}
