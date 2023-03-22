import 'dart:async';
import 'dart:isolate';
import 'typedefs.dart';

FutureOr<T> useIsolate<T, Q>(
  Q message,
  IsolateComputation<T, Q> computation, {
  IsolateDataToJson<T>? toJson,
  IsolateDataFromJson<T>? fromJson,
}) async {
  assert(toJson != null && fromJson != null);

  final result = Completer<T>();

  final receivePort = ReceivePort();

  await Isolate.spawn(
    IsolateRunner.run,
    IsolateRunner<T, Q>(
      computation: computation,
      sendPort: receivePort.sendPort,
      message: message,
      toJson: toJson!,
    ),
  );

  receivePort.first.then((value) {
    receivePort.close();

    if (value == null) {
      result.completeError(RemoteError("Computation ended without result", ""));
    }

    result.complete(fromJson!(value));
  });

  return result.future;
}

class IsolateRunner<T, Q> {
  static void run(IsolateRunner runner) => runner._run();

  final SendPort sendPort;
  final Q message;
  final IsolateComputation<T, Q> computation;
  final IsolateDataToJson<T> toJson;

  IsolateRunner({
    required this.computation,
    required this.sendPort,
    required this.message,
    required this.toJson,
  });

  void _run() async {
    T result;

    try {
      var potentiallyAsyncResult = computation(message);

      if (potentiallyAsyncResult is Future<T>) {
        result = await potentiallyAsyncResult;
      } else {
        result = potentiallyAsyncResult;
      }
    } catch (e, s) {
      final error = {
        "error": e,
        "stackTrace": s,
      }.toString();

      Isolate.exit(sendPort, error);
    }

    Isolate.exit(sendPort, toJson(result));
  }
}
