import 'dart:async';
import 'dart:convert';
import 'package:simple_http_api/simple_http_api.dart';

void main() async {
  await _uploadSingle("./assets/demo.gif");
  // await _uploadMulti();
}

Future<void> _uploadSingle(String path) async {
  final url = Uri.parse("http://127.0.0.1:8080/upload/single");
  final file = await FormData.fileFromPath(
    path,
    field: "single",
  );
  print(file);

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

Future<void> _uploadMulti() async {
  final url = Uri.parse("http://127.0.0.1:8080/upload/multi");
  final file1 =
      await FormData.fileFromPath("./assets/demo.mp4", field: "multi");

  final file2 =
      await FormData.fileFromPath("./assets/demo.png", field: "multi");

  final formData = FormData();

  formData.addFile(file1);
  formData.addFile(file2);

  formData.addFields({"upload": "test"});

  try {
    final res = await Api.upload(
      url,
      formData,
      cancelToken: TimingToken(Duration(seconds: 3)),
      headers: {
        "content-type": "application/json",
      },
    );
    print(res);
  } catch (e) {
    print("e");
  }
}
