import 'dart:async';
import 'dart:convert';

import 'models/models.dart';
import 'multipart/form_data.dart';
import 'response/api_response.dart';

import 'method_enum.dart';

import 'clients/clients.dart';

/// [CancelToken] and [ConnectionOption] would work together
/// it would depend on which condition is validated successfully first.
/// If [CancelToken] is validated successfully first, all [ConnectionOption] would not be validated any more
/// if [ConnectionOption] is validated successfully first, [CancelToken] would not be validated any more
///
/// no matter which one is validated successfully, the corresponding exception would be thrown
///
/// 1) How [CancelToken] is validated?
/// if no response is returned or no exception is thrown in [CancelToken.duration],
/// [CancelToken] is validated and then [CancelToken.cancel] is invoked to cancel the request.
/// a final [ApiError] with [ErrorType.cancel] would be thrown
///
/// 2) How [ConnectionOption] is validated?
/// - if the connection is not established in [ConnectionOption.connectionTimeout], throw [ErrorType.connectionTimeout]
/// - if the request data is not sent completely in [ConnectionOption.sendTimeout], throw [ErrorType.sendTimeout]
/// - if the response data is not received completely in [ConnectionOption.receiveTimeout], throw [ErrorType.receiveTimeout]
/// once the [ApiError] is thrown, the request would be aborted
abstract class Client {
  Client();

  factory Client.single([RetryConfig? config]) =>
      config != null ? RetryClient(config) : SingleRequestClient();

  factory Client.multipart() => MultipartClient();

  Future<ApiResponse> get(Uri url,
          {Map<String, String>? headers,
          CancelToken? cancelToken,
          ConnectionOption? options}) =>
      throw UnimplementedError(
          "[$runtimeType not implemented upload. Please using [SingleRequestClient]/[RetryClient]]");

  Future<ApiResponse> head(
    Uri url, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
    ConnectionOption? options,
  }) =>
      throw UnimplementedError(
          "[$runtimeType not implemented upload. Please using [SingleRequestClient]/[RetryClient]]");

  Future<ApiResponse> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CancelToken? cancelToken,
    ConnectionOption? options,
  }) =>
      throw UnimplementedError(
          "[$runtimeType not implemented upload. Please using [SingleRequestClient]/[RetryClient]]");

  Future<ApiResponse> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CancelToken? cancelToken,
    ConnectionOption? options,
  }) =>
      throw UnimplementedError(
          "[$runtimeType not implemented upload. Please using [SingleRequestClient]/[RetryClient]]");

  Future<ApiResponse> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CancelToken? cancelToken,
    ConnectionOption? options,
  }) =>
      throw UnimplementedError(
          "[$runtimeType not implemented upload. Please using [SingleRequestClient]/[RetryClient]]");

  Future<ApiResponse> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CancelToken? cancelToken,
    ConnectionOption? options,
  }) =>
      throw UnimplementedError(
          "[$runtimeType not implemented upload. Please using [SingleRequestClient]/[RetryClient]]");

  Future<ApiResponse> upload(
    Uri url,
    FormData formData, {
    ApiMethod method = ApiMethod.post,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    ConnectionOption? options,
    OnProgressCallback? onUploadProgress,
  }) =>
      throw UnimplementedError(
          "[$runtimeType not implemented upload. Please using [MultipartClient]");

  void close({bool force = false});
}
