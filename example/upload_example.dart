import 'dart:async';
import 'dart:isolate';
import 'dart:convert';
import 'package:simple_http_api/simple_http_api.dart';

void main() async {
  await _uploadMulti(null);
}

Future<void> _uploadSingle(String path) async {
  final url = Uri.parse("http://127.0.0.1:8080/upload/single");
  final file = await FormData.fileFromPath(
    path,
    field: "single",
  );

  final formData = FormData();

  formData.addFile(file);

  final nestedJson = {"nest": "json"};

  formData.addFields({
    "upload": "test",
    "nested": json.encode(nestedJson),
  });

  try {
    final res = await Api.upload(
      url, formData,
      // cancelToken: TimingToken(Duration(milliseconds: 100)),
      // headers: {
      //   "content-type": "application/json",
      // },
      onUploadProgress: (sent, total) =>
          print("total: $total, sent: $sent, percent: ${sent / total}"),
    );
    print(res);
  } catch (e) {
    print(e);
  }
}

Future<ApiResponse> _uploadMulti(OnProgressCallback? onProgress) async {
  final url = Uri.parse("http://127.0.0.1:8080/upload/multi");
  final file1 =
      await FormData.fileFromPath("./assets/demo.mp4", field: "multi");

  // final file2 =
  //     await FormData.fileFromPath("./assets/demo.png", field: "multi");

  final formData = FormData();

  formData.addFile(file1);
  // formData.addFile(file2);

  formData.addFields({
    "upload": "test",
    "delay": "delay",
  });

  return Api.upload(
    url,
    formData,
    cancelToken: TimingToken(Duration(seconds: 3)),
    headers: {
      "content-type": "application/json",
    },
    onUploadProgress: onProgress,
    useIsolate: true,
  );
}

// Future<String> uploadParallel() async {
//   final result = Completer<String>();

//   final receivePort = ReceivePort();

//   final isolate = await Isolate.spawn(
//     _uploadEntryPoint,
//     receivePort.sendPort,
//     onExit: receivePort.sendPort,
//   );

//   isolate.addOnExitListener(receivePort.sendPort, response: "DONE");

//   dynamic lastMessage;

//   StreamSubscription? sub;
//   receivePort.listen(
//     (message) {
//       print(message);

//       if (message == "DONE") {
//         receivePort.close();
//       } else {
//         lastMessage = message;
//       }
//     },
//     onDone: () {
//       print("isolate down");
//       result.complete(lastMessage.toString());
//     },
//   );

//   return result.future;
// }

// void _uploadEntryPoint(SendPort sendPort) async {
//   // void onProgress(int loaded, int total) {
//   //   sendPort.send({
//   //     "loaded": loaded,
//   //     "total": total,
//   //   });
//   // }

//   final res = await _uploadMulti(null);

//   try {
//     Isolate.exit(sendPort, {"res", res.toString()});
//   } catch (e) {
//     print(e);
//   }
// }
