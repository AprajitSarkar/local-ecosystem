// lib/core/logging/app_logger.dart

import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class AppLogger {
  AppLogger._();
  static final AppLogger instance = AppLogger._();

  void debug(String tag, String message) => _log(LogLevel.debug, tag, message);
  void info(String tag, String message) => _log(LogLevel.info, tag, message);
  void warning(String tag, String message) => _log(LogLevel.warning, tag, message);
  void error(String tag, String message, [Object? error, StackTrace? stack]) {
    _log(LogLevel.error, tag, message);
    if (error != null) {
      print('[$tag] ERROR detail: $error');
      if (stack != null) print(stack.toString());
    }
  }

  void _log(LogLevel level, String tag, String message) {
    final prefix = switch (level) {
      LogLevel.debug   => '🔵 DEBUG',
      LogLevel.info    => '🟢 INFO ',
      LogLevel.warning => '🟡 WARN ',
      LogLevel.error   => '🔴 ERROR',
    };
    print('$prefix [$tag] $message');
  }
}

final logger = AppLogger.instance;
