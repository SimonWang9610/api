import 'dart:async';
import 'dart:convert';

import 'models/models.dart';
import 'multipart/form_data.dart';
import 'response/api_response.dart';

import 'method_enum.dart';

import 'clients/clients.dart';

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
