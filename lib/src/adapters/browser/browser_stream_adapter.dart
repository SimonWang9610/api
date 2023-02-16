import 'dart:html';
import 'dart:async';

import '../../response/response_chunk.dart';
import '../../request/base_request.dart';
import '../../http_client_adapter.dart';
import '../../models/error.dart';

import '../../utils.dart';
import 'browser_request_wrapper.dart';

class BrowserStreamAdapter extends HttpClientAdapter
    with RequestWrapperManagement<_EventSourceRequest> {
  static const String responseType = "text";

  final bool withCredentials;

  BrowserStreamAdapter(this.withCredentials);

  @override
  void fetchStream(request, responseStream, [cancelToken]) async {
    final dataStream = request.finalize();
    cancelToken?.start();

    final eventSource = createHttpRequestWrapper(request);

    eventSource.listenProgressData(request, responseStream);
    eventSource.listenLoadEnd(responseStream);
    eventSource.listenError(responseStream);

    eventSource.registerCancelToken(() {
      if (!responseStream.isClosed) {
        responseStream.addError(
          ApiError(
            type: ErrorType.cancel,
            message: 'Request is canceled',
          ),
        );
        responseStream.close();

        return true;
      }
      return false;
    });

    eventSource.registerReceivingTimeout(() {
      if (!responseStream.isClosed) {
        responseStream.addError(
          ApiError(
            type: ErrorType.receiveTimeout,
            message:
                'Receiving timed out in ${request.receiveTimeout!.inMilliseconds}ms',
          ),
          StackTrace.current,
        );
        responseStream.close();
        return true;
      }
      return false;
    });

    eventSource.registerConnectingTimeout(() {
      final connected = eventSource.xhr.readyState >= HttpRequest.OPENED;
      if (!(connected || responseStream.isClosed)) {
        responseStream.addError(
          ApiError(
              type: ErrorType.connectionTimeout,
              message:
                  'Connecting timed out in ${request.connectionTimeout!.inMilliseconds}ms'),
        );
        responseStream.close();

        return true;
      }
      return false;
    });

    // todo: registerSendingTimeout & onUploadProgress

    try {
      final data = await dataStream.toBytes();
      eventSource.send(data);
    } catch (e) {
      if (!responseStream.isClosed) {
        responseStream.addError(assureApiError(e));
        responseStream.close();
      }
    } finally {
      eventSource.clear();
      remove(eventSource);
    }
  }

  @override
  _EventSourceRequest createHttpRequestWrapper(BaseRequest request) {
    final xhr = HttpRequest()
      ..open(request.method, "${request.url}")
      ..responseType = responseType
      ..withCredentials = withCredentials;

    final eventSource = _EventSourceRequest(
      xhr,
      option: request.options,
      cancelToken: request.cancelToken,
    );

    setConnection(request, eventSource);
    return eventSource;
  }
}

class _EventSourceRequest extends BrowserRequestWrapper {
  int _loaded = 0;
  int? _receiveStart;

  _EventSourceRequest(
    super.xhr, {
    required super.option,
    super.cancelToken,
  });

  /// [HttpRequest.responseText] is incremental instead of part data
  ///! consequently, if the data sent is large, it might overwhelm memory
  void listenProgressData(
      BaseRequest request, StreamController<ResponseChunk> controller) {
    final sub = xhr.onProgress.listen((event) {
      final chunk = xhr.responseText!.substring(_loaded);

      _loaded = xhr.responseText!.length;

      final chunkResponse = ResponseChunk(
        request: request,
        chunk: chunk,
        statusCode: xhr.status!,
        headers: xhr.responseHeaders,
        isRedirect: xhr.status == 301 || xhr.status == 302,
        statusMessage: xhr.statusText,
      );

      if (!controller.isClosed) {
        controller.add(chunkResponse);
      }
    });

    addSubscription(sub);
  }

  void listenLoadEnd(StreamController<ResponseChunk> controller) {
    final sub = xhr.onLoadEnd.listen((event) {
      if (!controller.isClosed) {
        controller.close();
      }
    });

    addSubscription(sub);
  }

  void listenError(StreamController<ResponseChunk> controller) {
    final sub = xhr.onError.listen((event) {
      if (!controller.isClosed) {
        controller.addError(
          ApiError(
            type: ErrorType.other,
            message: "XMLHttpRequest error",
          ),
          StackTrace.current,
        );
        controller.close();
      }
    });
    addSubscription(sub);
  }
}