import 'dart:async';
import 'dart:convert';

import '../models/models.dart';
import '../request/api_request.dart';
import '../response/api_response.dart';
import '../response/response_body.dart';
import '../method_enum.dart';
import '../utils.dart';

import 'single_request_client.dart';

class RetryClient extends SingleRequestClient {
  final RetryConfig config;

  RetryClient(this.config);

  RetryToken? _retryToken;

  @override
  Future<ApiResponse> create(
    ApiMethod method,
    Uri url,
    Map<String, String>? headers, {
    Object? body,
    Encoding? encoding,
    CancelToken? cancelToken,
    ConnectionOption? options,
    Encoding? responseEncoding,
  }) async {
    print("sending with retrying");
    ApiRequest? request;

    int i = 1;

    for (;;) {
      final canceledByMainToken = cancelToken?.isCanceled ?? false;

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
        resBody = await sendRequest(request, _retryToken);
      } catch (e) {
        final exception = assureApiError(e);
        final continueRetry = i < config.retries &&
            (config.retryWhenException?.call(exception) ?? true) &&
            !canceledByMainToken;
        if (!continueRetry) {
          _retryToken?.expire();
          throw exception;
        }
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
          _retryToken?.expire();
          return ApiResponse.fromStream(
            resBody,
            defaultEncoding: responseEncoding,
          );
        }
      }

      // [RetryToken.token] is always the fast completed [Future] if its has a main token
      // therefore, the token would be completed once the main token is canceled
      try {
        await _retryToken!.token;
      } catch (e) {
        _retryToken?.expire();
        if (e is TokenException) {
          throw ApiError(
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
      throw ApiError(
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
      final request = createApiRequest(method, url,
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
