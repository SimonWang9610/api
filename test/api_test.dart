import 'package:extended_http/extended_http.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    setUp(() {
      // Additional setup goes here.
    });

    final url = "http://10.0.0.165:8080/normal";

    Api.get(Uri.parse(url));

    test('First Test', () {});
  });
}
