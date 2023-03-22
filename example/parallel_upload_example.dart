import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:simple_http_api/simple_http_api.dart';

void main() async {
  // final res = await useIsolate<ApiResponse, String>(
  //   "./assets/demo.mp4",
  //   _upload,
  //   serializer: serialize,
  //   deserializer: deserialize,
  // );

  final res = await _upload("");

  print("final : $res");
}

Future<ApiResponse> _upload(path) async {
  final url = Uri.parse("http://127.0.0.1:8080/upload/multi");
  final file1 =
      await FormData.fileFromPath("./assets/demo.mp4", field: "multi");

  final formData = FormData();

  formData.addFile(file1);

  final nestedJson = {"nest": "json"};

  formData.addFields({
    "upload": "test",
    "nested": json.encode(nestedJson),
  });

  return Api.upload(
    url,
    formData,
    cancelToken: TimingToken(Duration(seconds: 3)),
    headers: {
      "content-type": "application/json",
    },
    // onUploadProgress: onProgress,
    useIsolate: true,
  );
}
