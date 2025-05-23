/// Result class used to return a value or an error message from a function.
/// The value can be null if the function does not return a value.
/// The error message can be null if the function does not return an error message.
/// Used to return the result of a failable asynchronous operation.
class Result<T> {
  /// The value to be returned by the function.
  final T? value;

  /// The error message to be returned by the function.
  final String? error;

  /// Constructor of the Result class.
  Result({this.value, this.error});

  /// Check if the result has a value.
  bool get hasError => error != null;
}
