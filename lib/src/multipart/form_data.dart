import 'package:http_parser/http_parser.dart';

import 'multipart_file.dart';
import '../utils.dart';

class FormData {
  final Map<String, String> _fields = {};
  final List<MultipartFile> _files = [];

  FormData();

  Map<String, String> get fields => Map.unmodifiable(_fields);
  List<MultipartFile> get files => List.unmodifiable(_files);

  static MultipartFile fileFromBytes(List<int> bytes,
          {required String field, String? filename, MediaType? contentType}) =>
      MultipartFile.fromBytes(
        field,
        bytes,
        filename: filename,
        contentType: contentType,
      );

  static MultipartFile fileFromString(String value,
          {required String field, String? filename, MediaType? contentType}) =>
      MultipartFile.fromString(
        field,
        value,
        filename: filename,
        contentType: contentType,
      );

  static MultipartFile fileFromStream(Stream<List<int>> stream,
          {required String field,
          required int length,
          String? filename,
          MediaType? contentType}) =>
      MultipartFile(
        field,
        stream,
        length,
        filename: filename,
        contentType: contentType,
      );

  static Future<MultipartFile> fileFromPath(String filePath,
          {required String field, String? filename, MediaType? contentType}) =>
      MultipartFile.fromPath(
        field,
        filePath,
        filename: filename,
        contentType: contentType,
      );

  void addFields(Map<String, String> values) => _fields.addAll(values);

  void addFile(MultipartFile file) {
    if (file.filename == null) {
      warningLog(
          "No [filename] provided for [$file]. It may lead your server to ignore the binary file data. Try to set a [filename] as much as possible unless you deliberately do that.");
    }
    _files.add(file);
  }

  void addFileFromBytes(List<int> bytes,
      {required String field, String? filename, MediaType? contentType}) {
    _files.add(fileFromBytes(
      bytes,
      field: field,
      filename: filename,
      contentType: contentType,
    ));
  }

  void addFileFromString(String value,
      {required String field, String? filename, MediaType? contentType}) {
    _files.add(fileFromString(
      value,
      field: field,
      filename: filename,
      contentType: contentType,
    ));
  }

  void addFileFromStream(Stream<List<int>> stream,
      {required String field,
      required int length,
      String? filename,
      MediaType? contentType}) {
    _files.add(fileFromStream(
      stream,
      field: field,
      length: length,
      filename: filename,
      contentType: contentType,
    ));
  }
}
