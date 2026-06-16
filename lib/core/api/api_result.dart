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
  const ApiError(this.message, {this.statusCode, this.cause});
  final String message;
  final int? statusCode;
  final Object? cause;

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound     => statusCode == 404;
  bool get isOffline      => statusCode == null;

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
