import 'dart:async';

import 'typedefs.dart';

FutureOr<T> useIsolate<T, Q>(
  Q message,
  IsolateComputation<T, Q> computation, {
  IsolateDataToJson<T>? toJson,
  IsolateDataFromJson<T>? fromJson,
}) async {
  await null;

  return computation(message);
}
