/// An error whose message is safe to show to the user.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Turns any error into a message for a snackbar or error state.
String friendlyError(Object error) {
  if (error is AppException) return error.message;
  final text = error.toString();
  if (text.contains('network') || text.contains('unavailable')) {
    return 'No internet connection. Please try again when you are online.';
  }
  if (text.contains('permission-denied')) {
    return 'You do not have permission to do that.';
  }
  return 'Something went wrong. Please try again.';
}
