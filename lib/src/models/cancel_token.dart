import 'dart:async';

class CancelToken {
  final Completer _completer;

  bool _started = false;

  CancelToken._() : _completer = Completer();

  factory CancelToken([Duration? duration]) {
    if (duration == null) {
      return CancelToken._();
    } else {
      return TimingToken(duration);
    }
  }

  void start() {
    _started = true;
  }

  void cancel(dynamic signal) {
    print("token canceling");
    if (_completer.isCompleted) return;
    _completer.complete(signal);
  }

  Future get token => _completer.future;

  bool get isCanceled => _completer.isCompleted;
}

class TimingToken extends CancelToken {
  final Duration duration;
  TimingToken(this.duration, [dynamic signal]) : super._();

  @override
  void start() {
    if (_started) return;

    super.start();
    Future.delayed(duration, () => cancel(null));
  }
}

/// when [mainToken] completes, [RetryToken] should be expired by invoking [cancel]
/// when [RetryToken] starts, the [mainToken] should also start
class RetryToken extends CancelToken {
  final CancelToken? mainToken;
  final Duration duration;
  final int count;

  RetryToken(this.duration, [this.mainToken, this.count = 0]) : super._();

  RetryToken retry([Duration? interval]) {
    return RetryToken(interval ?? duration, mainToken, count + 1);
  }

  void _cancelByMain() {
    if (_completer.isCompleted) return;
    _completer.completeError(TokenException());
  }

  @override
  void start() {
    if (_started) return;
    super.start();
    mainToken?.start();
    mainToken?.token.whenComplete(_cancelByMain);

    Timer(duration, () {
      // final skipCancel = mainToken?.isCanceled ?? false;

      // if (!skipCancel) cancel(count);
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
  TokenException([this.reason = "not cancel by it self"]);

  @override
  String toString() {
    return "TokenException($reason)";
  }
}
