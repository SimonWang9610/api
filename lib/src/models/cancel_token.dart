import 'dart:async';
import 'dart:developer';

abstract class CancelToken {
  final Completer _completer;
  final Duration duration;
  Timer? _timer;

  bool _started = false;

  CancelToken(this.duration) : _completer = Completer() {
    token.whenComplete(() => cancel(null));
  }

  void start() {
    if (_started) return;
    _started = true;
    _timer = _createTokenTimer();
    // print("$runtimeType $hashCode has started its [Timer].");
  }

  void cancel(dynamic signal) {
    _cancelTimer();
    if (_completer.isCompleted || !_started) return;
    _completer.complete(signal);
  }

  void _cancelTimer() {
    if (_timer != null) {
      // print(
      //     "$runtimeType $hashCode has canceled its [Timer]. It may happen to its [cancel] event, or ");
      _timer?.cancel();
      _timer = null;
    }
  }

  Timer? _createTokenTimer();

  Future get token => _completer.future;

  bool get isCanceled => _completer.isCompleted;
}

class TimingToken extends CancelToken {
  TimingToken(super.duration);

  @override
  Timer _createTokenTimer() {
    return Timer(duration, () => cancel(null));
  }
}

/// when [mainToken] completes, [RetryToken] should be expired by invoking [cancel]
/// when [RetryToken] starts, the [mainToken] should also start
class RetryToken extends CancelToken {
  final CancelToken? mainToken;
  final int count;

  RetryToken(super.duration, [this.mainToken, this.count = 0]);

  RetryToken refresh([Duration? interval]) {
    _cancelTimer();
    return RetryToken(interval ?? duration, mainToken, count + 1);
  }

  void _cancelByMain() {
    _cancelTimer();
    if (_completer.isCompleted) return;
    _completer.completeError(TokenException());
  }

  @override
  Timer _createTokenTimer() {
    mainToken?.start();
    mainToken?.token.whenComplete(_cancelByMain);
    return Timer(duration, () {
      cancel(count);
    });
  }

  /// its [Future] token should always be the fast one
  /// typically, [mainToken] would complete later than [RetryToken]
  @override
  Future get token {
    final tokens = [super.token];
    if (mainToken != null) {
      tokens.add(mainToken!.token);
    }
    return Future.any(tokens);
  }
}

class TokenException implements Exception {
  final String reason;
  const TokenException([this.reason = "not cancel by it self"]);

  @override
  String toString() {
    return "TokenException($reason)";
  }
}
