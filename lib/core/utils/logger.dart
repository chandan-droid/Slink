import 'package:flutter/foundation.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// A comprehensive utility for color-coded, well-structured console logging.
class AppLogger {
  AppLogger._();

  static const String _reset = '\x1B[0m';
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _cyan = '\x1B[36m';

  /// Granular debugging logs, e.g. state changes, UI rendering, local storage details
  static void debug(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Informational logs, e.g. service starts, screen navigations, network responses
  static void info(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Warning logs, e.g. connection drops, cache misses, minor errors
  static void warning(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Error logs, e.g. database write failure, critical exceptions, failed API calls
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void _log(LogLevel level, String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (!kDebugMode) return;

    final String emoji;
    final String color;

    switch (level) {
      case LogLevel.debug:
        emoji = '🛠️';
        color = _cyan;
        break;
      case LogLevel.info:
        emoji = 'ℹ️';
        color = _green;
        break;
      case LogLevel.warning:
        emoji = '⚠️';
        color = _yellow;
        break;
      case LogLevel.error:
        emoji = '🚨';
        color = _red;
        break;
    }

    final timestamp = DateTime.now().toIso8601String().substring(11, 23); // HH:mm:ss.SSS
    final tagStr = tag != null ? '[$tag]' : '';
    
    // Split the message into lines to preserve indent alignment on multiline logs
    final lines = message.split('\n');
    final formattedMessage = lines.map((line) => '$color$emoji [$timestamp]$tagStr $line$_reset').join('\n');

    // Print to console
    // Using standard print is perfect for understandable console debugging in Flutter/Dart
    // We use print here as requested to make it stand out directly in terminal
    debugPrint(formattedMessage);

    if (error != null) {
      debugPrint('$color  ↳ Error: $error$_reset');
    }
    if (stackTrace != null) {
      debugPrint('$color  ↳ StackTrace:\n$stackTrace$_reset');
    }
  }
}
