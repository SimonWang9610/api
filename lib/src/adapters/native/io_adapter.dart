import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../../response/response_body.dart';
import '../../request/base_request.dart';

import '../../models/error.dart';
import '../../http_client_adapter.dart';

import 'io_adapter_mixin.dart';

class IoClientAdapter extends HttpClientAdapter with IoAdapterMixin {
  @override
  Future<ResponseBody> fetch(request, [cancelToken]) async {
    checkClosed();

    final dataStream = request.finalize();
    cancelToken?.start();

    final httpClient = createHttpClient(
      request.options,
      cancelToken: cancelToken?.token,
      cancelCallback: (client) {
        try {
          client.close(force: true);
        } catch (e) {
          // todo: handle close error
        }
      },
    );

    final connectedRequest = await timingConnect(
      httpClient,
      request,
      onException: (e) {
        if (e is SocketException && e.message.contains("timed out")) {
          _throwConnectingTimeout(request.connectionTimeout);
        } else if (e is TimeoutException) {
          _throwConnectingTimeout(request.connectionTimeout);
        } else {
          _throwOtherException(e);
        }
        return false;
      },
    );

    await sendingWithTimeout(
      connectedRequest,
      dataStream,
      request,
      onException: (e) {
        if (e is TimeoutException) {
          connectedRequest.abort();
          throw ApiError(
            type: ErrorType.sendTimeout,
            message:
                "Sending timed out in ${request.sendTimeout?.inMilliseconds}ms",
          );
        } else {
          _throwOtherException(e);
        }
        return false;
      },
    );

    int receiveStart = DateTime.now().millisecondsSinceEpoch;

    final HttpClientResponse streamedResponse = await receiveWithTimeout(
      connectedRequest,
      request,
      onException: (e) {
        if (e is TimeoutException) {
          httpClient.close(force: true);
          throw ApiError(
            type: ErrorType.receiveTimeout,
            message: "Timed out in ${request.receiveTimeout?.inMilliseconds}",
            method: request.method,
            url: request.url.toString(),
          );
        } else {
          _throwOtherException(e);
        }
        return false;
      },
    );

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
            sink.close();

            // ! error on finding the connection associated with the response
            // ! if we try to detach its socket
            // response
            //     .detachSocket()
            //     .then((socket) => socket.destroy())
            //     .catchError(
            //   (err) {
            //     print("error on detaching socket: $err");
            //   },
            //   test: (error) => true,
            // );
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
}
