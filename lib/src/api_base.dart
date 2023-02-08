import 'dart:async';
import 'dart:convert';

import 'models/error.dart';
import 'models/cancel_token.dart';
import 'request/api_request.dart';
import 'models/connection_option.dart';
import 'response/api_response.dart';
import 'response/response_body.dart';

import 'adapter_stub.dart'
// ignore: uri_does_not_exist
    if (dart.library.html) 'adapters/browser_adapter.dart'
// ignore: uri_does_not_exist
    if (dart.library.io) 'adapters/io_adapter.dart';

import 'http_client_adapter.dart';

import "utils.dart";

enum ApiMethod {
  get("GET"),
  post("POST"),
  patch("PATCH"),
  head("HEAD"),
  put("PUT"),
  delete("DELETE");

  final String value;
  const ApiMethod(this.value);
}

class Client {
  final HttpClientAdapter _adapter = createAdapter();

  Client();

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

  Future<ApiResponse> _send(
    ApiMethod method,
    Uri url,
    Map<String, String>? headers, {
    Object? body,
    Encoding? encoding,
    CancelToken? cancelToken,
    ConnectionOption? options,
  }) async {
    final request = ApiRequest(method.value, url);

    if (options != null) {
      request.options = options;
    }

    request.cancelToken = cancelToken?.token;

    setRequestBody(request, headers, body, encoding);

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

  void setRequestBody(ApiRequest request, Map<String, String>? headers,
      [Object? body, Encoding? encoding]) {
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
  }

  void close({bool force = false}) {
    _adapter.close(force: force);
  }
}

class RetryConfig {
  final Duration retryTimeout;
  final int retries;
  final WhenException? retryWhenException;
  final WhenResponseStatus? retryWhenStatus;

  const RetryConfig({
    required this.retryTimeout,
    required this.retries,
    this.retryWhenException,
    this.retryWhenStatus,
  });
}

typedef WhenException = bool Function(RequestException);
typedef WhenResponseStatus = bool Function(int);

class RetryClient extends Client {
  final RetryConfig config;

  RetryClient(this.config) {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _timestamp++;
      print("seconds: $_timestamp");
    });
  }

  int _timestamp = 0;
  late Timer _timer;

  RetryToken? _retryToken;

  @override
  void close({bool force = false}) {
    super.close(force: force);
    _timer.cancel();
  }

  @override
  Future<ApiResponse> _send(
    ApiMethod method,
    Uri url,
    Map<String, String>? headers, {
    Object? body,
    Encoding? encoding,
    CancelToken? cancelToken,
    ConnectionOption? options,
  }) async {
    ApiRequest? request;

    int i = 0;

    for (;;) {
      final canceledByMainToken = cancelToken?.isCanceled ?? false;

      // when the [cancelToken] is expired
      // we should stop retrying since [cancelToken] is the main token associated with the retry token
      if (canceledByMainToken) {
        throw RequestException(
          type: ErrorType.cancel,
          message: "canceled by the given cancel token, so stopping retrying",
        );
      }

      _refreshToken(i, cancelToken);

      request = _createRequest(
        method,
        url,
        headers,
        old: request,
        body: body,
        encoding: encoding,
        cancelToken: cancelToken,
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

        if (!continueRetry) {
          return ApiResponse.fromStream(resBody);
        }
      }

      // once the cancel token is completed/expired/canceled
      // the current retry token will also be canceled
      // so the below await would be executed instantly
      // and continue the next iteration fastly
      // however, it would throw [ErrorType.cancel] before the next iteration goes through
      // due to the cancellation of the main token
      try {
        // once retry token starts, it will complete after its duration
        // here instead of start a new request instantly
        // we wait for the retry token is canceled
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
    if (count == 0) {
      _retryToken = RetryToken(config.retryTimeout, mainToken);
    } else {
      _retryToken = _retryToken!.retry();
    }
  }

  ApiRequest _createRequest(
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
      final request = ApiRequest(method.value, url);

      if (options != null) {
        request.options = options;
      }

      request.cancelToken = _retryToken?.token;

      setRequestBody(request, headers, body, encoding);
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
          cancelToken: _retryToken!.token,
        );
    }
  }
}
