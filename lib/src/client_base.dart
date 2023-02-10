import 'dart:async';
import 'dart:convert';
import 'package:meta/meta.dart';

import 'models/models.dart';
import 'multipart/form_data.dart';
import 'request/api_request.dart';
import 'request/multi_part_request.dart';
import 'request/base_request.dart';
import 'response/api_response.dart';
import 'response/response_body.dart';

import 'adapter_stub.dart'
// ignore: uri_does_not_exist
    if (dart.library.html) 'adapters/browser_adapter.dart'
// ignore: uri_does_not_exist
    if (dart.library.io) 'adapters/io_adapter.dart';

import 'http_client_adapter.dart';
import 'method_enum.dart';

import "utils.dart";

abstract class Client {
  final HttpClientAdapter _adapter = createAdapter();

  Client._();

  factory Client([RetryConfig? config, bool disableRetry = false]) {
    if (config != null && !disableRetry) {
      return _RetryClient(config);
    } else {
      return _SingleRequestClient();
    }
  }

  Future<ApiResponse> get(Uri url,
      {Map<String, String>? headers,
      CancelToken? cancelToken,
      ConnectionOption? options});

  Future<ApiResponse> head(
    Uri url, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
    ConnectionOption? options,
  });

  Future<ApiResponse> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CancelToken? cancelToken,
    ConnectionOption? options,
  });

  Future<ApiResponse> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CancelToken? cancelToken,
    ConnectionOption? options,
  });

  Future<ApiResponse> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CancelToken? cancelToken,
    ConnectionOption? options,
  });

  Future<ApiResponse> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CancelToken? cancelToken,
    ConnectionOption? options,
  });

  Future<ApiResponse> upload(
    Uri url,
    FormData formData, {
    ApiMethod method = ApiMethod.post,
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CancelToken? cancelToken,
    ConnectionOption? options,
    OnProgressCallback? onUploadProgress,
  });

  void close({bool force = false}) {
    _adapter.close(force: force);
  }
}

class _SingleRequestClient extends Client {
  _SingleRequestClient() : super._();

  @override
  Future<ApiResponse> get(
    Uri url, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
    ConnectionOption? options,
  }) =>
      _send(
        ApiMethod.get,
        url,
        headers,
        cancelToken: cancelToken,
        options: options,
      );

  @override
  Future<ApiResponse> head(
    Uri url, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
    ConnectionOption? options,
  }) =>
      _send(
        ApiMethod.head,
        url,
        headers,
        cancelToken: cancelToken,
        options: options,
      );

  @override
  Future<ApiResponse> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CancelToken? cancelToken,
    ConnectionOption? options,
  }) =>
      _send(
        ApiMethod.post,
        url,
        headers,
        body: body,
        encoding: encoding,
        cancelToken: cancelToken,
        options: options,
      );

  @override
  Future<ApiResponse> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CancelToken? cancelToken,
    ConnectionOption? options,
  }) =>
      _send(
        ApiMethod.put,
        url,
        headers,
        body: body,
        encoding: encoding,
        cancelToken: cancelToken,
        options: options,
      );

  @override
  Future<ApiResponse> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CancelToken? cancelToken,
    ConnectionOption? options,
  }) =>
      _send(
        ApiMethod.patch,
        url,
        headers,
        body: body,
        encoding: encoding,
        cancelToken: cancelToken,
        options: options,
      );

  @override
  Future<ApiResponse> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CancelToken? cancelToken,
    ConnectionOption? options,
  }) =>
      _send(
        ApiMethod.delete,
        url,
        headers,
        body: body,
        encoding: encoding,
        cancelToken: cancelToken,
        options: options,
      );

  @override
  Future<ApiResponse> upload(
    Uri url,
    FormData formData, {
    ApiMethod method = ApiMethod.post,
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CancelToken? cancelToken,
    ConnectionOption? options,
    OnProgressCallback? onUploadProgress,
  }) =>
      _send(
        method,
        url,
        headers,
        formData: formData,
        cancelToken: cancelToken,
        options: options,
        onUploadProgress: onUploadProgress,
      );

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

  ApiRequest _createApiRequest(
    ApiMethod method,
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    final request = ApiRequest(method.value, url);

    if (headers != null) request.headers.addAll(headers);

    if (encoding != null) request.encoding = encoding;
    if (body != null) {
      if (body is String) {
        request.body = body;
      } else if (body is List) {
        request.bodyBytes = body.cast<int>();
      } else if (body is Map) {
        request.bodyFields = body.cast<String, String>();
      } else {
        throw ArgumentError('Invalid request body "$body".');
      }
    }
    return request;
  }

  Future<ApiResponse> _send(
    ApiMethod method,
    Uri url,
    Map<String, String>? headers, {
    FormData? formData,
    Object? body,
    Encoding? encoding,
    CancelToken? cancelToken,
    ConnectionOption? options,
    OnProgressCallback? onUploadProgress,
  }) async {
    final request = formData != null
        ? _createMultipartRequest(
            method,
            url,
            formData,
            headers: headers,
            onUploadProgress: onUploadProgress,
          )
        : _createApiRequest(method, url,
            headers: headers, encoding: encoding, body: body);

    if (options != null) {
      request.options = options;
    }

    request.cancelToken = cancelToken?.token;

    late ApiResponse res;
    try {
      cancelToken?.start();
      final resBody = await _adapter.fetch(request);
      res = await ApiResponse.fromStream(resBody);
    } catch (e) {
      throw assureRequestException(e);
    }

    return res;
  }
}

class _RetryClient extends _SingleRequestClient {
  final RetryConfig config;

  _RetryClient(this.config);

  RetryToken? _retryToken;

  @override
  Future<ApiResponse> _send(
    ApiMethod method,
    Uri url,
    Map<String, String>? headers, {
    Object? body,
    Encoding? encoding,
    CancelToken? cancelToken,
    ConnectionOption? options,
    FormData? formData,
    OnProgressCallback? onUploadProgress,
  }) async {
    print("sending with retrying");
    ApiRequest? request;

    int i = 1;

    for (;;) {
      final canceledByMainToken = cancelToken?.isCanceled ?? false;

      // // when the [cancelToken] is expired
      // // we should stop retrying since [cancelToken] is the main token associated with the retry token
      // if (canceledByMainToken) {
      //   throw RequestException(
      //     type: ErrorType.cancel,
      //     message: "canceled by the given cancel token, so stopping retrying",
      //   );
      // }

      _refreshToken(i, cancelToken);
      print("trying on $i");

      request = _createRequestFromOld(
        method,
        url,
        headers,
        old: request,
        body: body,
        encoding: encoding,
        cancelToken: cancelToken,
        options: options,
      );

      ResponseBody? resBody;

      try {
        _retryToken!.start();

        resBody = await _adapter.fetch(request);
      } catch (e) {
        final exception = assureRequestException(e);
        final continueRetry = i < config.retries &&
            (config.retryWhenException?.call(exception) ?? true) &&
            !canceledByMainToken;
        if (!continueRetry) throw exception;
      }

      if (resBody != null) {
        final continueRetry = i < config.retries &&
            (config.retryWhenStatus?.call(resBody.statusCode) ?? true) &&
            !canceledByMainToken;

        print(
            "api status: ${resBody.statusCode}, continue retry $continueRetry");
        print("main token canceled: ${cancelToken?.isCanceled ?? false}");

        // log("api status: ${resBody.statusCode}, need retry: $continueRetry");
        // log("main token canceled: ${cancelToken?.isCanceled ?? false}");

        if (!continueRetry) {
          return ApiResponse.fromStream(resBody);
        }
      }

      // [RetryToken.token] is always the fast completed [Future] if its has a main token
      // therefore, the token would be completed once the main token is canceled
      try {
        await _retryToken!.token;
      } catch (e) {
        if (e is TokenException) {
          throw RequestException(
            type: ErrorType.cancel,
            message: e.reason,
          );
        } else {
          rethrow;
        }
      }

      i++;
    }
  }

  void _refreshToken(int count, [CancelToken? mainToken]) {
    if (mainToken != null && mainToken.isCanceled) {
      throw RequestException(
        type: ErrorType.cancel,
        message: "canceled by the given cancel token, so stopping retrying",
      );
    }

    if (count == 1) {
      _retryToken = RetryToken(config.retryTimeout, mainToken);
    } else {
      _retryToken = _retryToken!.refresh();
    }
  }

  ApiRequest _createRequestFromOld(
    ApiMethod method,
    Uri url,
    Map<String, String>? headers, {
    ApiRequest? old,
    Object? body,
    Encoding? encoding,
    CancelToken? cancelToken,
    ConnectionOption? options,
  }) {
    if (old == null) {
      final request = _createApiRequest(method, url,
          headers: headers, encoding: encoding, body: body);

      if (options != null) {
        request.options = options;
      }

      request.cancelToken = _retryToken?.token;

      return request;
    } else {
      return ApiRequest(old.method, old.url)
        ..bodyBytes = old.bodyBytes
        ..headers.addAll(old.headers)
        ..encoding = old.encoding
        ..options = ConnectionOption(
          sendTimeout: old.sendTimeout,
          receiveTimeout: old.receiveTimeout,
          connectionTimeout: old.connectionTimeout,
          persistentConnection: old.persistentConnection,
          followRedirects: old.followRedirects,
          maxDirects: old.maxRedirects,
        )
        ..cancelToken = _retryToken!.token;
    }
  }
}
