// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'dart:typed_data';
import 'dart:async';

import '../../response/response_body.dart';
import '../../request/base_request.dart';
import '../../models/error.dart';
import '../../http_client_adapter.dart';
import 'browser_request_wrapper.dart';

class BrowserAdapter extends HttpClientAdapter
    with RequestWrapperManagement<_HttpRequestWrapper> {
  static const String responseType = "arraybuffer";

  final bool withCredentials;

  BrowserAdapter(this.withCredentials);

  @override
  Future<ResponseBody> fetch(request, [cancelToken]) async {
    final dataStream = request.finalize();
    cancelToken?.start();

    final wrapper = createHttpRequestWrapper(request);

    final completer = Completer<ResponseBody>();

    wrapper.listenDataLoaded(completer, request);
    wrapper.listenError(completer);

    wrapper.registerConnectingTimeout(() {
      final connected = wrapper.xhr.readyState >= HttpRequest.OPENED;
      if (!(connected || completer.isCompleted)) {
        completer.completeError(
          ApiError(
              type: ErrorType.connectionTimeout,
              message:
                  'Connecting timed out in ${request.connectionTimeout!.inMilliseconds}ms'),
        );
        return true;
      }
      return false;
    });

    wrapper.registerCancelToken(
      () {
        if (!completer.isCompleted) {
          completer.completeError(
            ApiError(
              type: ErrorType.cancel,
              message: 'Request is canceled',
            ),
          );

          return true;
        }
        return false;
      },
    );
    wrapper.registerReceivingTimeout(
      () {
        if (!completer.isCompleted) {
          completer.completeError(
            ApiError(
              type: ErrorType.receiveTimeout,
              message:
                  'Receiving timed out in ${request.receiveTimeout!.inMilliseconds}ms',
            ),
            StackTrace.current,
          );
          return true;
        }
        return false;
      },
    );

    wrapper.registerSendingTimeout(() {
      if (wrapper.receiveStart == null &&
          !completer.isCompleted &&
          wrapper.xhr.readyState < HttpRequest.HEADERS_RECEIVED) {
        completer.completeError(
          ApiError(
            type: ErrorType.sendTimeout,
            message:
                'Sending timed out in ${request.sendTimeout!.inMilliseconds}ms]',
          ),
        );
        return true;
      }
      return false;
    });

    if (request.shouldReportUploadProgress) {
      wrapper.onUploadProgress((event) {
        if (event.loaded != null && event.total != null) {
          request.onUploadProgressCallback?.call(event.loaded!, event.total!);
        }
      });
    }

    final data = await dataStream.toBytes();
    wrapper.send(data);

    return completer.future.whenComplete(
      () {
        wrapper.clear();
        remove(wrapper);
      },
    );
  }

  @override
  // ignore: library_private_types_in_public_api
  _HttpRequestWrapper createHttpRequestWrapper(BaseRequest request) {
    final wrapper = _HttpRequestWrapper(
      HttpRequest()
        ..open(request.method, "${request.url}")
        ..responseType = responseType
        ..withCredentials = withCredentials,
      option: request.options,
      cancelToken: request.cancelToken,
    );

    setConnection(request, wrapper);
    return wrapper;
  }
}

typedef ProgressEventHandler = void Function(ProgressEvent);
typedef ReadStateEventHandler = void Function(Event);

/// store all [StreamSubscription] for [HttpRequest]
/// so that release all subscriptions when the request is fulfilled/aborted
class _HttpRequestWrapper extends BrowserRequestWrapper {
  _HttpRequestWrapper(
    super.xhr, {
    required super.option,
    super.cancelToken,
  });

  void onUploadProgress(ProgressEventHandler handler) {
    final sub = xhr.upload.onProgress.listen(handler);
    addSubscription(sub);
  }

  /// connecting timeout if the ready state of xhr does not become [HttpRequest.OPENED] during [option.connectionTimeout]
  /// to avoid invoking the connection timeout handler, should check the ready state of xhr and if the result has been completed

  void listenDataLoaded(
      Completer<ResponseBody> completer, BaseRequest request) {
    final sub = xhr.onLoad.listen((event) {
      if (!completer.isCompleted) {
        final body = (xhr.response as ByteBuffer).asUint8List();
        completer.complete(
          ResponseBody(
            request: request,
            stream: Stream.value(body),
            statusCode: xhr.status!,
            headers: xhr.responseHeaders,
            isRedirect: xhr.status == 301 || xhr.status == 302,
            statusMessage: xhr.statusText,
          ),
        );
      }
    });
    addSubscription(sub);
  }

  void listenError(Completer<ResponseBody> completer) {
    final sub = xhr.onError.listen((event) {
      if (!completer.isCompleted) {
        completer.completeError(
          ApiError(
            type: ErrorType.other,
            message: "XMLHttpRequest error",
          ),
          StackTrace.current,
        );
      }
    });
    addSubscription(sub);
  }
}
