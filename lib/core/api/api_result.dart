/// Why an [ApiError] happened, distinguishing failure modes the UI should
/// present differently — a stale connection reads very differently to a user
/// than a validation error.
enum NetworkReason {
  /// Couldn't reach the server at all (DNS failure, connection refused, no
  /// network). Covers both "no internet" and "server is down" — Dio can't
  /// reliably tell those apart without an extra connectivity dependency, so
  /// both are surfaced as "can't reach the server".
  noConnection,

  /// The request reached the server (or a proxy) but it didn't respond in
  /// time.
  timeout,

  /// The server responded with a 5xx — it's up, but erroring.
  serverError,

  /// The token is missing/expired/invalid for a protected endpoint.
  unauthorized,

  /// The server responded with a 4xx that isn't an auth problem — bad
  /// input, not found, conflict, etc.
  requestFailed,

  /// Anything else (unexpected exception, parse failure, ...).
  unknown,
}

/// Sealed result type used by every repository method that touches the network.
///
/// Usage:
/// ```dart
/// final result = await friendService.fetchFriends();
/// switch (result) {
///   case ApiSuccess(:final data): renderList(data);
///   case ApiError(:final message): showError(message);
/// }
/// ```
sealed class ApiResult<T> {
  const ApiResult();
}

final class ApiSuccess<T> extends ApiResult<T> {
  const ApiSuccess(this.data);
  final T data;
}

final class ApiError<T> extends ApiResult<T> {
  const ApiError(
    this.message, {
    this.statusCode,
    this.cause,
    this.reason = NetworkReason.unknown,
  });
  final String message;
  final int? statusCode;
  final Object? cause;
  final NetworkReason reason;

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound     => statusCode == 404;
  bool get isOffline      => reason == NetworkReason.noConnection;

  @override
  String toString() => 'ApiError[$statusCode]: $message';
}

/// Convenience extension so callers can do result.dataOrNull / result.errorOrNull.
extension ApiResultX<T> on ApiResult<T> {
  T? get dataOrNull   => this is ApiSuccess<T> ? (this as ApiSuccess<T>).data : null;
  String? get errorOrNull => this is ApiError<T> ? (this as ApiError<T>).message : null;
  bool get isSuccess  => this is ApiSuccess<T>;
  bool get isError    => this is ApiError<T>;
}
