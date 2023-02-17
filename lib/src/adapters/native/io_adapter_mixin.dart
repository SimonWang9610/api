import 'dart:async';
import 'dart:io';

import '../../http_client_adapter.dart';
import '../../models/connection_option.dart';
import '../../models/byte_stream.dart';
import '../../request/base_request.dart';

typedef ExceptionCallback = bool Function(Object);

typedef CancelCallback = void Function(HttpClient);

mixin IoAdapterMixin on HttpClientAdapter {
  HttpClient? _client;
  bool _closed = false;

  void checkClosed() {
    if (_closed) {
      throw Exception(
          "Can't establish connection after [HttpClientAdapter] closed!");
    }
  }

  @override
  void close({bool force = false}) {
    _closed = true;
    _client?.close(force: force);
  }

  HttpClient createHttpClient(
    ConnectionOption options, {
    Future? cancelToken,
    CancelCallback? cancelCallback,
  }) {
    final idleTimeout =
        cancelToken == null ? const Duration(seconds: 3) : const Duration();

    if (cancelToken != null) {
      final HttpClient client = HttpClient();

      client.userAgent = null;
      client.idleTimeout = idleTimeout;

      cancelToken.whenComplete(
        () {
          cancelCallback?.call(client);
        },
      );

      client.connectionTimeout = options.connectionTimeout;
      return client;
    }

    if (_client == null) {
      _client = HttpClient();
      _client!.idleTimeout = idleTimeout;
      _client!.connectionTimeout = options.connectionTimeout;
    }
    return _client!;
  }

  Future<HttpClientRequest> timingConnect(
      HttpClient client, BaseRequest request,
      {required ExceptionCallback onException}) async {
    late HttpClientRequest connectedRequest;

    try {
      Future<HttpClientRequest> connecting =
          client.openUrl(request.method, request.url);

      if (request.options.validConnectionTimeout) {
        connecting = connecting.timeout(request.connectionTimeout!);
      }

      connectedRequest = await connecting;
    } catch (e) {
      if (onException(e)) {
        rethrow;
      }
    }

    request.headers.forEach((key, value) {
      connectedRequest.headers.set(key, value);
    });

    connectedRequest.followRedirects = request.followRedirects;
    connectedRequest.maxRedirects = request.maxRedirects;
    connectedRequest.persistentConnection = request.persistentConnection;
    connectedRequest.contentLength = (request.contentLength ?? -1);

    return connectedRequest;
  }

  Future<void> sendingWithTimeout(
    HttpClientRequest clientRequest,
    ProgressedBytesStream dataStream,
    BaseRequest request, {
    required ExceptionCallback onException,
  }) async {
    try {
      Future sending = clientRequest.addStream(dataStream.progressingUpload());

      if (request.options.validSendTimeout) {
        sending = sending.timeout(request.sendTimeout!);
      }

      await sending;
    } catch (e) {
      if (onException(e)) {
        rethrow;
      }
    }
  }

  Future<HttpClientResponse> receiveWithTimeout(
      HttpClientRequest clientRequest, BaseRequest request,
      {required ExceptionCallback onException}) async {
    late HttpClientResponse streamedResponse;

    try {
      Future<HttpClientResponse> closing = clientRequest.close();

      // must set timeout here
      // since the timeout is expired once we start receiving data
      // it is same as xhr.onLoadStart
      if (request.options.validReceiveTimeout) {
        closing = closing.timeout(request.receiveTimeout!);
      }
      streamedResponse = await closing;
    } catch (e) {
      if (onException(e)) {
        rethrow;
      }
    }

    return streamedResponse;
  }
}
