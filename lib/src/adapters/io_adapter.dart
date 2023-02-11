import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../response/response_body.dart';
import '../request/base_request.dart';
import '../models/connection_option.dart';
import '../models/byte_stream.dart';
import '../models/error.dart';
import '../http_client_adapter.dart';

HttpClientAdapter createAdapter([bool withCredentials = false]) =>
    IoClientAdapter();

class IoClientAdapter extends HttpClientAdapter {
  HttpClient? _client;
  bool _closed = false;

  @override
  Future<ResponseBody> fetch(request, [cancelToken]) async {
    _checkClosed();

    final dataStream = request.finalize();
    cancelToken?.start();

    final httpClient = _createHttpClient(request.options, request.cancelToken);

    final connectedRequest = await _connectWithTimeout(httpClient, request);

    await _sendingWithTimeout(connectedRequest, dataStream, request);

    int receiveStart = DateTime.now().millisecondsSinceEpoch;

    final HttpClientResponse streamedResponse =
        await _receiveWithTimeout(connectedRequest, request, httpClient);

    return _receiveResponseData(
        streamedResponse, receiveStart, request, httpClient);
  }

  ResponseBody _receiveResponseData(HttpClientResponse response, int start,
      BaseRequest request, HttpClient client) {
    final stream = response.transform<Uint8List>(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          final timeoutInMs = request.receiveTimeout?.inMilliseconds;
          final current = DateTime.now().millisecondsSinceEpoch;

          if (timeoutInMs != null &&
              current - start > timeoutInMs &&
              request.options.validReceiveTimeout) {
            sink.addError(
              ApiError(
                type: ErrorType.receiveTimeout,
                message: "Receiving timed out in $timeoutInMs ms",
                method: request.method,
                url: request.url.toString(),
              ),
              StackTrace.current,
            );
            // ! error on finding the connection associated with the response
            // ! if we try to detach its socket
            // response.detachSocket().then((socket) => socket.destroy());
            client.close(force: true);
          } else {
            sink.add(Uint8List.fromList(data));
          }
        },
        handleError: (error, stackTrace, sink) {
          sink.close();
        },
      ),
    );

    final Map<String, String> headers = {};

    response.headers.forEach((key, values) {
      headers[key] = values.join(",");
    });

    return ResponseBody(
      request: request,
      stream: stream,
      contentLength: response.contentLength,
      statusCode: response.statusCode,
      headers: headers,
      isRedirect: response.isRedirect || response.redirects.isNotEmpty,
      statusMessage: response.reasonPhrase,
      persistentConnection: response.persistentConnection,
    );
  }

  HttpClient _createHttpClient(ConnectionOption options,
      [Future? cancelToken]) {
    final idleTimeout =
        cancelToken == null ? const Duration(seconds: 3) : const Duration();

    if (cancelToken != null) {
      final HttpClient client = HttpClient();

      client.userAgent = null;
      client.idleTimeout = idleTimeout;
      cancelToken.whenComplete(
        () {
          print("canceling complete");

          try {
            client.close(force: true);
          } catch (e) {
            // todo: handle close error
          }
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

  Future<HttpClientRequest> _connectWithTimeout(
      HttpClient client, BaseRequest request) async {
    late HttpClientRequest connectedRequest;

    try {
      Future<HttpClientRequest> connecting =
          client.openUrl(request.method, request.url);

      if (request.options.validConnectionTimeout) {
        connecting.timeout(request.connectionTimeout!);
      }

      connectedRequest = await connecting;

      request.headers.forEach((key, value) {
        connectedRequest.headers.set(key, value);
      });
    } on SocketException catch (e) {
      if (e.message.contains("timed out")) {
        _throwConnectingTimeout(request.connectionTimeout);
      }
      _throwOtherException(e);
    } on TimeoutException {
      _throwConnectingTimeout(request.connectionTimeout);
    } catch (e) {
      _throwOtherException(e);
    }

    connectedRequest.followRedirects = request.followRedirects;
    connectedRequest.maxRedirects = request.maxRedirects;
    connectedRequest.persistentConnection = request.persistentConnection;
    connectedRequest.contentLength = (request.contentLength ?? -1);

    return connectedRequest;
  }

  Future<void> _sendingWithTimeout(HttpClientRequest clientRequest,
      ProgressedBytesStream dataStream, BaseRequest request) async {
    try {
      Future sending = clientRequest.addStream(dataStream.progressingUpload());

      if (request.options.validSendTimeout) {
        sending = sending.timeout(request.sendTimeout!);
      }

      await sending;
    } on TimeoutException {
      clientRequest.abort();
      throw ApiError(
        type: ErrorType.sendTimeout,
        message:
            "Sending timed out in ${request.sendTimeout?.inMilliseconds}ms",
      );
    } catch (e) {
      _throwOtherException(e);
    }
  }

  Future<HttpClientResponse> _receiveWithTimeout(
      HttpClientRequest clientRequest,
      BaseRequest request,
      HttpClient client) async {
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
    } on TimeoutException {
      //! once the timeout throws, we should close the client forcely
      //! otherwise, the application may be stuck
      client.close(force: true);

      throw ApiError(
        type: ErrorType.receiveTimeout,
        message: "Timed out in ${request.receiveTimeout?.inMilliseconds}",
        method: request.method,
        url: request.url.toString(),
      );
    } catch (e) {
      _throwOtherException(e);
    }
    return streamedResponse;
  }

  void _checkClosed() {
    if (_closed) {
      throw Exception(
          "Can't establish connection after [HttpClientAdapter] closed!");
    }
  }

  void _throwConnectingTimeout(Duration? connectionTimeout) {
    throw ApiError(
      type: ErrorType.connectionTimeout,
      message: "Timed out in $connectionTimeout",
    );
  }

  void _throwOtherException(Object e) {
    if (e is HttpException) {
      throw ApiError(
        type: ErrorType.cancel,
        message: "$e",
      );
    } else {
      throw ApiError(
        type: ErrorType.other,
        message: "$e",
      );
    }
  }

  @override
  void close({bool force = false}) {
    _closed = true;
    _client?.close(force: force);
  }
}
