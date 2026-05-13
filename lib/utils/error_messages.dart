import 'package:dio/dio.dart';

String friendlyError(Object? error) {
  if (error is DioException) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Request timed out. The server may be waking up — try again in a moment.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'No connection. Check your internet and try again.';
    }
    return switch (error.response?.statusCode) {
      400 => 'Bad request. Try again in a few minutes.',
      401 => 'Unauthorized. Check your proxy configuration.',
      403 => 'Access denied.',
      404 => 'Player not found. Check the name and platform.',
      410 => 'Unknown platform. Use PC, PS4, X1, or SWITCH.',
      429 => 'Rate limit reached. Wait a moment and try again.',
      500 => 'Server error. Try again later.',
      502 || 503 => 'Service unavailable. The proxy or Apex API may be down.',
      _ => 'Network error (${error.response?.statusCode ?? "unknown"}).',
    };
  }
  final msg = error?.toString() ?? 'Unknown error';
  if (msg.startsWith('Exception: ')) return msg.substring(11);
  return msg;
}
