import 'dart:async';
import 'dart:io';

import '../../response/response_chunk.dart';
import '../../models/error.dart';
import '../../utils.dart';
import '../../http_client_adapter.dart';
import 'io_adapter_mixin.dart';

class IoStreamAdapter extends HttpClientAdapter with IoAdapterMixin {
  @override
  void fetchStream(request, responseStream, [cancelToken]) async {
    checkClosed();

    final dataStream = request.finalize();
    cancelToken?.start();

    final httpClient = createHttpClient(
      request.options,
      cancelToken: cancelToken?.token,
      cancelCallback: (client) {
        if (!responseStream.isClosed) {
          responseStream.addError(
            ApiError(
              type: ErrorType.cancel,
              message: 'Request is canceled',
            ),
          );
          responseStream.close();
          try {
            client.close(force: true);
          } catch (e) {
            // todo: handle close error
          }
        }
      },
    );
    final connectedRequest = await timingConnect(
      httpClient,
      request,
      onException: (e) {
        if (e is SocketException && e.message.contains("timed out")) {
          _closeWithConnectTimeout(responseStream, request.connectionTimeout);
        } else if (e is TimeoutException) {
          _closeWithConnectTimeout(responseStream, request.connectionTimeout);
        } else {
          _closeWithOtherError(responseStream, e);
        }
      },
    );
    await sendingWithTimeout(
      connectedRequest,
      dataStream,
      request,
      onException: (e) {
        if (e is TimeoutException) {
          connectedRequest.abort();
          responseStream.addError(ApiError(
            type: ErrorType.sendTimeout,
            message:
                "Sending timed out in ${request.sendTimeout?.inMilliseconds}ms",
          ));
          responseStream.close();
        } else {
          _closeWithOtherError(responseStream, e);
        }
      },
    );

    int receiveStart = DateTime.now().millisecondsSinceEpoch;

    final HttpClientResponse streamedResponse = await receiveWithTimeout(
      connectedRequest,
      request,
      onException: (e) {
        if (e is TimeoutException) {
          httpClient.close(force: true);
          responseStream.addError(ApiError(
            type: ErrorType.receiveTimeout,
            message: "Timed out in ${request.receiveTimeout?.inMilliseconds}",
            method: request.method,
            url: request.url.toString(),
          ));
          responseStream.close();
        } else {
          _closeWithOtherError(responseStream, e);
        }
      },
    );

    final Map<String, String> headers = {};

    streamedResponse.headers.forEach((key, values) {
      headers[key] = values.join(",");
    });

    streamedResponse.listen(
      (data) {
        final timeoutInMs = request.receiveTimeout?.inMilliseconds;
        final current = DateTime.now().millisecondsSinceEpoch;

        if (timeoutInMs != null &&
            current - receiveStart > timeoutInMs &&
            request.options.validReceiveTimeout &&
            !responseStream.isClosed) {
          responseStream.addError(
            ApiError(
              type: ErrorType.receiveTimeout,
              message: "Receiving timed out in $timeoutInMs ms",
              method: request.method,
              url: request.url.toString(),
            ),
          );
          responseStream.close();
          httpClient.close(force: true);
        } else if (!responseStream.isClosed) {
          final chunkResponse = IoChunk(
            data,
            request: request,
            statusCode: streamedResponse.statusCode,
            headers: headers,
            isRedirect: streamedResponse.isRedirect ||
                streamedResponse.redirects.isNotEmpty,
            statusMessage: streamedResponse.reasonPhrase,
            persistentConnection: streamedResponse.persistentConnection,
          );
          responseStream.add(chunkResponse);
        }
      },
      onError: (err) {
        if (!responseStream.isClosed) {
          responseStream.addError(
            ApiError(
              type: ErrorType.other,
              message: "Error on streaming remote data: $err",
              method: request.method,
              url: request.url.toString(),
            ),
            StackTrace.current,
          );
          responseStream.close();
          httpClient.close(force: true);
        }
      },
      onDone: responseStream.close,
    );
  }

  void _closeWithConnectTimeout(StreamController<BaseChunk> controller,
      [Duration? connectionTimeout]) {
    if (!controller.isClosed) {
      controller.addError(ApiError(
        type: ErrorType.connectionTimeout,
        message: "Timed out in $connectionTimeout",
      ));
      controller.close();
    }
  }

  void _closeWithOtherError(StreamController<BaseChunk> controller, Object e) {
    if (!controller.isClosed) {
      controller.addError(assureApiError(e));
      controller.close();
    }
  }
}
