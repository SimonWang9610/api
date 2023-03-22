import 'dart:async';

typedef IsolateComputation<T, Q> = FutureOr<T> Function(Q);
typedef IsolateDataToJson<T> = String Function(T);
typedef IsolateDataFromJson<T> = T Function(String);
