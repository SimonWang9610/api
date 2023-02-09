<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

This library allows users to create different API requests (e.g., get, post, put, delete, patch) by referring to [http](https://pub.dev/packages/http) and [dio](https://pub.dev/packages/dio)

## Features

1. Compared to `http` and `dio`, this library is very small and provide a different way to retry quest.
   It allows you to retry a request by setting a `Duration` instead of waiting a `Duration` simply after the previous request is returned

2. support canceling a request at any time

## Getting started

TODO: List prerequisites and provide or point to information on how to
start using the package.

## Usage

### Without retrying

- get request

```dart
import "package:api/api.dart";

void _get() async {
    final url = Uri.parse("http://127.0.0.1:8080");

    try {
        final res = await Api.get(
        url,
        headers: {"accept": "application/json"},
        cancelToken: TimingToken(Duration(seconds: 2)),
        options: ConnectionOption(
                connectionTimeout: Duration(seconds: 1),
                sendTimeout: Duration(seconds: 1),
                receiveTimeout: Duration(seconds: 3),
            ),
        );
        print(res);
    } catch (e) {
        print(e);
    }
}
```

- post request

```dart
import "dart:convert";
import "package:api/api.dart";

void _post_() async {
  final url = Uri.parse("http://127.0.0.1:8080");

  final data = {
    "hello": "api",
    "delay": "4000",
    "list": [100],
  };

  try {
    final res = await Api.post(
      url,
      headers: {
        "accept": "application/json",
        "content-type": "application/json",
      },
      cancelToken: TimingToken(Duration(seconds: 2)),
      body: json.encode(data),
      options: ConnectionOption(
        connectionTimeout: Duration(seconds: 1),
        sendTimeout: Duration(seconds: 1),
        receiveTimeout: Duration(seconds: 3),
      ),
    );
    print(res);
  } catch (e) {
    print(e);
  }
}
```

## Create a request

> Users must use try-catch to catch `RequestException` in case that no expected `ApiResponse` is returned (e.g., the request is aborted/timed out/, or the response is not as users expected)

1. Need to specify the `content-type` field in the headers. If not, it will fallback to different media types:

   - `body` is `String` -> `text/plain`
   - `body` is `Map<String, String>` or can be casted into `Map<String, String>` -> `application/x-www-form-urlencoded`
   - `body` is `List<int>` or can be casted into `List<int>` -> no fallback media type applied
     > if none of the above cases is applied to `body`, throw `ArgumentError` when setting `body`

2. (Optional) specify a kind of `CancelToken` to determine if canceling this request.

   - `TimingToken`: this token would start timing just before creating a `HttpRequest`/`XMLHttpRequest`. When its token is expired, it will invoke `cancel()` to complete. As a result, the `HttpRequest`/`XMLHttpRequest` would be aborted, and throw `ErrorType.cancel`
   - `RetryToken`: this token would behave as `TimingToken` if no `RetryConfig` is provided. If `RetryCOnfig` is provided, it will combine with its `mainToken` together to determine if canceling the current request and start retrying.

3. (Optional) specify a `ConnectionOption` to control the duration for different stages of a request.

   - (Web): all three kinds of timeout would try completing the `Completer` and then abort this `XMLHttpRequest` once one of them is validated successfully

     1. `connectionTimeout` would validate successfully if `XHR.readState < 1` after its duration
     2. `sendTimeout` would validate successfully if `XHR.readyState < 3` and a receive start time is set after its duration
     3. `receiveTimeout` would validate successfully if `onLoadStart` is invoked after its duration

   - (Mobile): `HttpClient` would be closed forcely once one of three timeouts validate successfully

   1. `connectionTimeout` is set when creating `HttpClient`
   2. `sendTimeout` is activated when starting `addStream` into `HttpClientRequest`
   3. `receiveTimeout` is activated in two stages: 1) trying to get response by invoking `HttpClientRequest.close()` 2) each data chunk is received

### How `ConnectionOption` works with `CancelToken`

> Typically, `CancelToken` could let users to determine 1) how long a request is expected to complete in total 2) need to ignore/abort a request once there are some cases happen unexpectedly/deliberately

> `ConnectionOption` let users determine how long a stage of requests is expected to complete. If a request spends more time than the given timeout at some stages, it would be aborted/canceled directly

`ConnectionOption` and `CancelToken` would validate themselves respectively and try to abort/cancel a request whichever is validated successfully

### How retrying is implemented

`RetryConfig.retries` limits the maximum retries, while `RetryConfig.retryInterval` limits the interval between two requests.

Users have two ways to stop retrying:

1. Providing a `CancelToken` to dominate the `RetryToken` that is created by `_RetryClient` and inaccessible directly. Once the `CancelToken` is expired, retry would be stopped and the current request would be aborted if applicable.

2. `RetryConfig.retryWhenException` and `RetryConfig.retryWhenStatus` work together and determine if continuing retrying before reaching the maximum retries.

The above ways can work together.

> Note: `RetryConfig.retryInterval` means the next request would be created and abort the previous one if no response is returned from the previous one between `retryInterval`, instead of waiting `retryInterval` after the previous request return a response.

## TODO

1. support `MultiPartRequest`
2. testing `delete`, `patch` and `put`
3. unit tests
