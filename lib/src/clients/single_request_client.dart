import 'dart:async';
import 'dart:convert';

import '../models/models.dart';
import '../request/api_request.dart';
import '../response/api_response.dart';
import '../method_enum.dart';
import '../utils.dart';

import '../client.dart';
import 'adapter_mixin.dart';

class SingleRequestClient extends Client with HttpAdapterManager {
  SingleRequestClient();

  @override
  Future<ApiResponse> get(
    Uri url, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
    ConnectionOption? options,
  }) =>
      create(
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
      create(
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
      create(
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
      create(
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
      create(
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
      create(
        ApiMethod.delete,
        url,
        headers,
        body: body,
        encoding: encoding,
        cancelToken: cancelToken,
        options: options,
      );

  ApiRequest createApiRequest(
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

  Future<ApiResponse> create(
    ApiMethod method,
    Uri url,
    Map<String, String>? headers, {
    Object? body,
    Encoding? encoding,
    CancelToken? cancelToken,
    ConnectionOption? options,
  }) async {
    final request = createApiRequest(method, url,
        headers: headers, encoding: encoding, body: body);

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
}
