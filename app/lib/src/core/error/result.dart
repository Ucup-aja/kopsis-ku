import 'app_exception.dart';

/// Result type to avoid throwing across repository boundaries.
/// Success carries [data]; failure carries [error] (user-safe).
sealed class Result<T> {
  const Result();
  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;
}

class Ok<T> extends Result<T> {
  final T data;
  const Ok(this.data);
}

class Err<T> extends Result<T> {
  final AppException error;
  const Err(this.error);
}
