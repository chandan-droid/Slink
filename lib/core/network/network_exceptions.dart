import 'package:dio/dio.dart';

class NetworkException implements Exception {
  final String message;
  final int? statusCode;

  const NetworkException({required this.message, this.statusCode});

  factory NetworkException.fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(
          message: 'Connection timed out. Please check your internet connection.',
        );

      case DioExceptionType.connectionError:
        return const NetworkException(
          message: 'Unable to connect to server. Please check your internet connection.',
        );

      case DioExceptionType.cancel:
        return const NetworkException(message: 'Request was cancelled.');

      case DioExceptionType.badCertificate:
        return const NetworkException(message: 'Security certificate verification failed.');

      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        final body = e.response?.data;
        String rawMsg = '';

        if (body is Map) {
          rawMsg = (body['message'] ?? body['error'] ?? '').toString();
        } else if (body is String) {
          rawMsg = body;
        }

        // Clean user-friendly message parsing
        String friendlyMsg = _formatServerErrorMessage(code, rawMsg);
        return NetworkException(message: friendlyMsg, statusCode: code);

      default:
        final raw = e.message ?? '';
        if (raw.contains('Failed host lookup') || raw.contains('SocketException')) {
          return const NetworkException(
            message: 'Unable to connect to server. Please check your internet connection.',
          );
        }
        return NetworkException(message: _cleanMessage(raw.isNotEmpty ? raw : 'An unexpected network error occurred.'));
    }
  }

  /// Parses server error messages into human-friendly text
  static String _formatServerErrorMessage(int? code, String rawMsg) {
    final lower = rawMsg.toLowerCase();

    if (lower.contains('phone number already registered') || lower.contains('duplicate') && lower.contains('phone')) {
      return 'This phone number is already registered. Please sign in instead.';
    }
    if (lower.contains('duplicate') && lower.contains('email')) {
      return 'This email address is already registered. Please use another email or sign in.';
    }
    if (lower.contains('invalid credentials') || code == 401) {
      return 'Incorrect phone number or password. Please try again.';
    }
    if (code == 403) {
      return 'Access denied. Please check your credentials or log in again.';
    }
    if (code == 404) {
      return 'Requested service or user not found.';
    }
    if (code != null && code >= 500) {
      if (lower.contains('duplicate')) {
        return 'An account with this phone number or email already exists.';
      }
      return 'Server is temporarily unavailable. Please try again in a moment.';
    }

    if (rawMsg.isNotEmpty && !rawMsg.startsWith('{')) {
      return _cleanMessage(rawMsg);
    }

    return 'Something went wrong. Please try again.';
  }

  /// Helper to convert any error (string, Exception, DioException) into a clean UI message
  static String parseError(dynamic error) {
    if (error == null) return 'An unexpected error occurred.';
    if (error is NetworkException) return error.message;
    if (error is DioException) return NetworkException.fromDioException(error).message;

    String s = error.toString();
    s = s.replaceFirst(RegExp(r'^Exception:\s*'), '');
    s = s.replaceFirst(RegExp(r'^DioException\s*\[.*?\]:\s*'), '');
    s = s.replaceFirst(RegExp(r'^Error:\s*'), '');

    if (s.contains('Failed host lookup') || s.contains('SocketException')) {
      return 'Unable to reach the server. Please check your internet connection.';
    }
    if (s.toLowerCase().contains('phone number already registered')) {
      return 'This phone number is already registered. Please sign in instead.';
    }
    if (s.toLowerCase().contains('invalid credentials')) {
      return 'Incorrect phone number or password. Please try again.';
    }

    return s.trim().isNotEmpty ? s.trim() : 'An unexpected error occurred.';
  }

  static String _cleanMessage(String msg) {
    var cleaned = msg.replaceFirst(RegExp(r'^Exception:\s*'), '');
    cleaned = cleaned.replaceFirst(RegExp(r'^DioException\s*\[.*?\]:\s*'), '');
    return cleaned.trim();
  }

  @override
  String toString() => message;
}
