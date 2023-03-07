import 'dart:io';

import 'package:http_parser/http_parser.dart';

import 'multipart_file.dart';

Future<MultipartFile> multipartFileFromPath(String field, String filePath,
    {String? filename, MediaType? contentType}) async {
  var segments = Uri.file(filePath).pathSegments;
  filename = segments.isNotEmpty ? segments.last : "";

  var file = File(filePath);
  var length = await file.length();
  return MultipartFile(
    field,
    file.openRead(),
    length,
    filename: filename,
    contentType: contentType,
  );
}
