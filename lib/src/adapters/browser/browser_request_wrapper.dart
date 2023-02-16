// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'dart:async';

import '../../request/base_request.dart';
import '../../http_client_adapter.dart';
import '../../models/connection_option.dart';
import '../../utils.dart';

typedef TimeoutCallback = bool Function();

abstract class BrowserRequestWrapper {
  final HttpRequest xhr;
  final Future? cancelToken;
  final ConnectionOption option;
  final Set<StreamSubscription> _subscriptions = {};

  BrowserRequestWrapper(this.xhr, {required this.option, this.cancelToken});

  void addSubscription(StreamSubscription sub) => _subscriptions.add(sub);

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

  int? _receiveStart;
  int? get receiveStart => _receiveStart;

  /// when loading start, mark the [_receiveStart] timestamp and start timing [option.receiveTimeout]
  /// if [completer] is not completed with either a [ResponseBody] or another [ApiError]
  void registerReceivingTimeout(TimeoutCallback callback) {
    final sub = xhr.onLoadStart.listen(
      (_) {
        _receiveStart ??= DateTime.now().millisecondsSinceEpoch;

        if (option.validReceiveTimeout) {
          Future.delayed(
            option.receiveTimeout!,
            () {
              if (callback()) {
                xhr.abort();
              }
            },
          );
        }
      },
    );

    addSubscription(sub);
  }

  /// when the ready state of xhr becomes [HttpRequest.OPENED], start timing [option.sendTimeout]
  /// this method should be invoked when the ready state of xhr is changing
  /// [option.sendTimeout] is validated successfully when
  /// 1) receiving is not starting ([_receiveStart] == null)
  /// 2) [completer] has not been completed which means either a [ResponseBody] is returned or other [ApiError]s is returned
  /// 3) the read state of xhr is still not changed to [HttpRequest.HEADERS_RECEIVED]
  void registerSendingTimeout(TimeoutCallback callback) {
    final sub = xhr.onReadyStateChange.listen((event) {
      if (xhr.readyState == HttpRequest.OPENED && option.validSendTimeout) {
        Future.delayed(option.sendTimeout!, () {
          if (callback()) {
            xhr.abort();
          }
        });
      }
    });
    addSubscription(sub);
  }

  /// cancel this request if the result has not been completed
  /// TODO: investigate possible issues if aborting this request brutely
  void registerCancelToken(TimeoutCallback callback) {
    if (cancelToken != null) {
      cancelToken!.whenComplete(() {
        if (callback()) {
          xhr.abort();
        }
      });
    }
  }

  void registerConnectingTimeout(TimeoutCallback callback) {
    if (option.validConnectionTimeout) {
      Future.delayed(
        option.connectionTimeout!,
        () {
          if (callback()) {
            xhr.abort();
          }
        },
      );
    }
  }
}

mixin RequestWrapperManagement<T extends BrowserRequestWrapper>
    on HttpClientAdapter {
  final _xhrs = <T>{};

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

  T createHttpRequestWrapper(BaseRequest request);

  void addWrapper(T wrapper) => _xhrs.add(wrapper);

  void remove(T wrapper) => _xhrs.remove(wrapper);

  void setConnection(BaseRequest request, T wrapper) {
    addWrapper(wrapper);

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
  }
}
