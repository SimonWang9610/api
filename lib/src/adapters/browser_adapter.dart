// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'dart:typed_data';
import 'dart:async';

import '../response/response_body.dart';
import '../request/base_request.dart';
import '../models/connection_option.dart';
import '../models/error.dart';
import '../utils.dart';
import '../http_client_adapter.dart';

HttpClientAdapter createAdapter([bool withCredentials = false]) =>
    BrowserAdapter(withCredentials);

class BrowserAdapter extends HttpClientAdapter {
  static const String responseType = "arraybuffer";

  final _xhrs = <_HttpRequestWrapper>{};

  final bool withCredentials;

  BrowserAdapter(this.withCredentials);

  @override
  Future<ResponseBody> fetch(request, [cancelToken]) async {
    final dataStream = request.finalize();
    cancelToken?.start();

    final wrapper = _createHttpRequest(request);

    final completer = Completer<ResponseBody>();

    wrapper.listenDataLoaded(completer, request);
    wrapper.listenError(completer);

    wrapper.registerConnectingTimeout(completer);
    wrapper.registerCancelToken(completer);
    wrapper.registerReceivingTimeout(completer);

    wrapper.listenReadyStateChange((_) {
      // print("current ready state: ${wrapper.xhr.readyState}");
      // print("receives start: ${wrapper._receiveStart}");

      wrapper.registerSendingTimeout(completer);
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
        _xhrs.remove(wrapper);
      },
    );
  }

  _HttpRequestWrapper _createHttpRequest(BaseRequest request) {
    final wrapper = _HttpRequestWrapper(
      HttpRequest()
        ..open(request.method, "${request.url}")
        ..responseType = responseType
        ..withCredentials = withCredentials,
      request.options,
      request.cancelToken,
    );
    _xhrs.add(wrapper);

    print("url: ${request.url}");

    removeContentLengthHeader(request.headers);
    request.headers.forEach(wrapper.xhr.setRequestHeader);

    final connectTimeoutMs = request.connectionTimeout?.inMilliseconds;
    final receiveTimeoutMs = request.receiveTimeout?.inMilliseconds;
    final sendTimeoutMS = request.sendTimeout?.inMilliseconds;

    if (connectTimeoutMs != null &&
        receiveTimeoutMs != null &&
        sendTimeoutMS != null) {
      wrapper.xhr.timeout = connectTimeoutMs + sendTimeoutMS + receiveTimeoutMs;
    }

    return wrapper;
  }

  @override
  void close({bool force = false}) {
    for (final request in _xhrs) {
      if (force) {
        request.close();
      } else {
        request.clear();
      }
    }

    _xhrs.clear();
  }
}

typedef ProgressEventHandler = void Function(ProgressEvent);
typedef ReadStateEventHandler = void Function(Event);

/// store all [StreamSubscription] for [HttpRequest]
/// so that release all subscriptions when the request is fulfilled/aborted
class _HttpRequestWrapper {
  final HttpRequest xhr;
  final ConnectionOption option;
  final Future? cancelToken;
  final Set<StreamSubscription> _subscriptions = {};

  _HttpRequestWrapper(this.xhr, this.option, [this.cancelToken]);

  int? _receiveStart;

  void onUploadProgress(ProgressEventHandler handler) {
    final sub = xhr.upload.onProgress.listen(handler);
    _subscriptions.add(sub);
  }

  void listenReadyStateChange(ReadStateEventHandler handler) {
    final sub = xhr.onReadyStateChange.listen(handler);
    _subscriptions.add(sub);
  }

  /// connecting timeout if the ready state of xhr does not become [HttpRequest.OPENED] during [option.connectionTimeout]
  /// to avoid invoking the connection timeout handler, should check the ready state of xhr and if the result has been completed
  void registerConnectingTimeout(Completer<ResponseBody> completer) {
    if (option.validConnectionTimeout) {
      Future.delayed(
        option.connectionTimeout!,
        () {
          final connected = xhr.readyState >= HttpRequest.OPENED;
          if (!(connected || completer.isCompleted)) {
            completer.completeError(
              ApiError(
                  type: ErrorType.connectionTimeout,
                  message:
                      'Connecting timed out in ${option.connectionTimeout!.inMilliseconds}ms'),
            );
            xhr.abort();
          }
        },
      );
    }
  }

  /// when the ready state of xhr becomes [HttpRequest.OPENED], start timing [option.sendTimeout]
  /// this method should be invoked when the ready state of xhr is changing
  /// [option.sendTimeout] is validated successfully when
  /// 1) receiving is not starting ([_receiveStart] == null)
  /// 2) [completer] has not been completed which means either a [ResponseBody] is returned or other [ApiError]s is returned
  /// 3) the read state of xhr is still not changed to [HttpRequest.HEADERS_RECEIVED]
  void registerSendingTimeout(Completer<ResponseBody> completer) {
    if (xhr.readyState == HttpRequest.OPENED && option.validSendTimeout) {
      Future.delayed(option.sendTimeout!, () {
        if (_receiveStart == null &&
            !completer.isCompleted &&
            xhr.readyState < HttpRequest.HEADERS_RECEIVED) {
          completer.completeError(
            ApiError(
              type: ErrorType.sendTimeout,
              message:
                  'Sending timed out in ${option.sendTimeout!.inMilliseconds}ms]',
            ),
          );
          xhr.abort();
        }
      });
    }
  }

  /// when loading start, mark the [_receiveStart] timestamp and start timing [option.receiveTimeout]
  /// if [completer] is not completed with either a [ResponseBody] or another [ApiError]
  void registerReceivingTimeout(Completer<ResponseBody> completer) {
    final sub = xhr.onLoadStart.listen(
      (_) {
        _receiveStart ??= DateTime.now().millisecondsSinceEpoch;

        if (option.validReceiveTimeout) {
          Future.delayed(
            option.receiveTimeout!,
            () {
              if (!completer.isCompleted) {
                completer.completeError(
                  ApiError(
                    type: ErrorType.receiveTimeout,
                    message:
                        'Receiving timed out in ${option.receiveTimeout!.inMilliseconds}ms',
                  ),
                  StackTrace.current,
                );
                xhr.abort();
              }
            },
          );
        }
      },
    );

    _subscriptions.add(sub);
  }

  /// cancel this request if the result has not been completed
  /// TODO: investigate possible issues if aborting this request brutely
  void registerCancelToken(Completer<ResponseBody> completer) async {
    if (cancelToken != null) {
      cancelToken!.whenComplete(() {
        if (!completer.isCompleted) {
          completer.completeError(
            ApiError(
              type: ErrorType.cancel,
              message: 'Request is canceled',
            ),
          );

          final readyState = xhr.readyState;

          if (readyState > HttpRequest.UNSENT &&
              readyState < HttpRequest.DONE) {
            xhr.abort();
          }
        }
      });
    }
  }

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
    _subscriptions.add(sub);
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
    _subscriptions.add(sub);
  }

  void send(dynamic data) {
    xhr.send(data);
  }

  void close() {
    clear();
    xhr.abort();
  }

  void clear() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }
}
