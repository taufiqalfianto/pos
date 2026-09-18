import 'package:logger/logger.dart';

/// Centralized logging service.
/// Use this instead of `print()` for consistent, filterable logs.
class AppLogger {
  AppLogger._();

  static const String _tag = 'POS';
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 100,
      colors: false,
      printEmojis: false,
      dateTimeFormat: DateTimeFormat.dateAndTime,
    ),
  );

  static void debug(String message, {String? tag}) {
    _logger.d(_messageWithTag(message, tag));
  }

  static void info(String message, {String? tag}) {
    _logger.i(_messageWithTag(message, tag));
  }

  static void warning(String message, {String? tag, Object? error}) {
    _logger.w(_messageWithTag(message, tag), error: error);
  }

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.e(
      _messageWithTag(message, tag),
      error: error,
      stackTrace: stackTrace,
    );
  }

  static String _messageWithTag(String message, String? tag) {
    return '[${tag ?? _tag}] $message';
  }
}
