import 'package:http_parser/http_parser.dart';

import 'multipart_file.dart';

Future<MultipartFile> multipartFileFromPath(String field, String filePath,
        {String? filename, MediaType? contentType}) =>
    throw UnsupportedError(
        'MultipartFile is only supported where dart:io is available.');
