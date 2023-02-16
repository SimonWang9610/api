import '../http_client_adapter.dart';

import 'browser/browser_adapter.dart';
import 'browser/browser_stream_adapter.dart';

HttpClientAdapter createAdapter(
    {bool withCredentials = false, bool asStream = false}) {
  if (asStream) {
    return BrowserStreamAdapter(withCredentials);
  } else {
    return BrowserAdapter(withCredentials);
  }
}
