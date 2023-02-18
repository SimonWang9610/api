import 'dart:async';

/// currently, only [TimingToken] and [RetryToken] are implemented
/// if [RetryToken] is not used in [RetryClient], it would behave as same as [TimingToken]
/// in future, we should enable users to create their subtypes of [CancelToken]
abstract class CancelToken {
  final Completer _completer;
  final Duration duration;
  Timer? _timer;

  bool _started = false;

  CancelToken(this.duration) : _completer = Completer() {
    token.whenComplete(() => cancel(null));
  }

  /// start the [token]. typically it is invoked when [BaseRequest] is finalized
  void start() {
    if (_started) return;
    _started = true;
    _timer = _createTokenTimer();
    // print("$runtimeType $hashCode has started its [Timer].");
  }

  /// cancel the current request. invoking it more than once would have no further effect
  void cancel(dynamic signal) {
    _cancelTimer();
    if (_completer.isCompleted || !_started) return;
    _completer.complete(signal);
  }

  /// just for syntax declaration, behave same as [cancel]
  /// used to declare this token has been expired,
  /// then trigger all subsequent callbacks in advance that are registered by .then and .whenComplete
  void expire() {
    cancel(null);
  }

  void _cancelTimer() {
    if (_timer != null) {
      // print(
      //     "$runtimeType $hashCode has canceled its [Timer]. It may happen to its [cancel] event, or ");
      _timer?.cancel();
      _timer = null;
    }
  }

  Timer? _createTokenTimer() => null;

  Future get token => _completer.future;

  bool get isCanceled => _completer.isCompleted;
}

/// requests would be canceled/aborted if no response is returned during [duration]
class TimingToken extends CancelToken {
  TimingToken(super.duration);

  @override
  Timer _createTokenTimer() {
    return Timer(duration, () => cancel(null));
  }
}

/// when [mainToken] completes, [RetryToken] should be expired by invoking [_cancelByMain]
/// when [RetryToken] starts, the [mainToken] should also start
class RetryToken extends CancelToken {
  final CancelToken? mainToken;
  final int count;

  RetryToken(super.duration, [this.mainToken, this.count = 0]);

  /// create a new [RetryToken] based on the current [count]
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

  @override
  void expire() {
    mainToken?.expire();
    super.expire();
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
