import '../http_client_adapter.dart';

import 'native/io_adapter.dart';
import 'native/io_stream_adapter.dart';

HttpClientAdapter createAdapter(
    {bool withCredentials = false, bool asStream = false}) {
  if (asStream) {
    return IoStreamAdapter();
  } else {
    return IoClientAdapter();
  }
}
