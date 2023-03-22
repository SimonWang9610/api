import 'dart:async';

import 'typedefs.dart';

/// [message] would be the only parameter for [computation]
/// the return result of [computation] would be serialized as string by [toJson],
/// so that it would be deserialized by [fromJson].
/// Therefore, [useIsolate] should not be used to decode the api response since it
/// is redundant.
/// only use it if the api request would cost much time, such as uploading a large file
FutureOr<T> useIsolate<T, Q>(
  Q message,
  IsolateComputation<T, Q> computation, {
  IsolateDataToJson<T>? toJson,
  IsolateDataFromJson<T>? fromJson,
}) =>
    throw UnimplementedError("Not supported on the current platform");
