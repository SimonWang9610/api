enum ApiMethod {
  get("GET"),
  post("POST"),
  patch("PATCH"),
  head("HEAD"),
  put("PUT"),
  delete("DELETE");

  final String value;
  const ApiMethod(this.value);
}
