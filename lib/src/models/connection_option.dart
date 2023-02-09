import 'package:meta/meta.dart';

@immutable
class ConnectionOption {
  final Duration? sendTimeout;
  final Duration? connectionTimeout;
  final Duration? receiveTimeout;
  final bool persistentConnection;
  final bool followRedirects;
  final int maxDirects;

  const ConnectionOption({
    this.sendTimeout,
    this.connectionTimeout,
    this.receiveTimeout,
    this.persistentConnection = true,
    this.followRedirects = true,
    this.maxDirects = 5,
  });

  static const defaultOption = ConnectionOption();

  ConnectionOption copyWith({
    Duration? sendTimeout,
    Duration? connectionTimeout,
    Duration? receiveTimeout,
    bool? persistentConnection,
    bool? followRedirects,
    int? maxDirects,
  }) {
    return ConnectionOption(
      sendTimeout: sendTimeout ?? this.sendTimeout,
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      persistentConnection: persistentConnection ?? this.persistentConnection,
      followRedirects: followRedirects ?? this.followRedirects,
      maxDirects: maxDirects ?? this.maxDirects,
    );
  }

  bool get validSendTimeout =>
      sendTimeout != null && sendTimeout!.inMilliseconds > 0;

  bool get validConnectionTimeout =>
      connectionTimeout != null && connectionTimeout!.inMilliseconds > 0;

  bool get validReceiveTimeout =>
      receiveTimeout != null && receiveTimeout!.inMilliseconds > 0;
}
