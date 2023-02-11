class MultipartField {
  final String key;
  final String value;
  final Map<String, String>? headers;

  MultipartField(this.key, this.value, {this.headers});
}
