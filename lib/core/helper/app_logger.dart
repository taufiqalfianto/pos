import 'dart:developer' as developer;

/// Centralized logging service.
/// Use this instead of `print()` for consistent, filterable logs.
class AppLogger {
  AppLogger._();

  static const String _tag = 'POS';

  static void debug(String message, {String? tag}) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 500, // Level below info
    );
  }

  static void info(String message, {String? tag}) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 800,
    );
  }

  static void warning(String message, {String? tag, Object? error}) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 900,
      error: error,
    );
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}