import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

typedef ByteStream = Stream<Uint8List>;
typedef OnProgressCallback = void Function(int, int);

Future<Uint8List> _toBytes(Stream<Uint8List> stream) {
  var completer = Completer<Uint8List>();
  var sink = ByteConversionSink.withCallback(
      (bytes) => completer.complete(Uint8List.fromList(bytes)));
  stream.listen(sink.add,
      onError: completer.completeError,
      onDone: sink.close,
      cancelOnError: true);
  return completer.future;
}

extension BytesConverterExt on ByteStream {
  Future<Uint8List> toBytes() => _toBytes(this);
}

class ProgressedBytesStream extends StreamView<Uint8List> {
  final int total;
  final OnProgressCallback? onUploadProgress;
  final bool shouldReportUploadProgress;

  const ProgressedBytesStream(
    this.total,
    super.stream, {
    this.onUploadProgress,
    this.shouldReportUploadProgress = false,
  });

  factory ProgressedBytesStream.empty() =>
      const ProgressedBytesStream(0, Stream.empty());

  Future<Uint8List> toBytes() => _toBytes(this);

  Stream<Uint8List> progressingUpload() {
    if (!shouldReportUploadProgress || onUploadProgress == null) return this;

    int consumed = 0;

    return transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          consumed += data.length;

          sink.add(data);

          onUploadProgress!(consumed, total);
        },
      ),
    );
  }
}
