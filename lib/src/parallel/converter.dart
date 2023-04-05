import 'dart:convert';
import 'dart:typed_data';

import 'package:simple_http_api/simple_http_api.dart';

String apiResponseToJson(ApiResponse res) {
  final map = {
    "bodyBytes": res.bodyBytes,
    "headers": res.headers,
    "isRedirect": res.isRedirect,
    "contentLength": res.contentLength,
    "persistentConnection": res.persistentConnection,
    "statusCode": res.statusCode,
    "statusMessage": res.statusMessage,
  };

  return json.encode(map);
}

ApiResponse jsonToApiResponse(String data) {
  final map = json.decode(data);

  final bytes = List.castFrom<dynamic, int>(map["bodyBytes"] as List<dynamic>);

  return ApiResponse(
    Uint8List.fromList(bytes),
    headers: (map["headers"] as Map<String, dynamic>).cast(),
    isRedirect: map["isRedirect"] as bool,
    persistentConnection: map["persistentConnection"] as bool,
    statusCode: map["statusCode"] as int,
    contentLength: map["contentLength"] as int?,
    statusMessage: map["statusMessage"] as String?,
  );
}
