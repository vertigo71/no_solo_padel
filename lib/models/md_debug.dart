import 'package:intl/intl.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:simple_logger/simple_logger.dart';

import '../utilities/ut_http_helper.dart';

abstract class MyLog {
  static final SimpleLogger _simpleLogger = SimpleLogger();
  static String _loggedUserId = '';

  static void setLoggedUserId(String userId) {
    _loggedUserId = userId;
    Sentry.configureScope(
      (scope) => scope.setUser(SentryUser(id: userId)),
    );
  }

  static String get loggedUserId => _loggedUserId;

  static const Level _kDefaultLevel = Level.INFO;

  /// initialize the logger
  static void initialize() {
    _simpleLogger.setLevel(_kDefaultLevel);
    _simpleLogger.formatter = (info) {
      final formattedTime = DateFormat('HH:mm:ss.SSS').format(info.time);
      final String levelString = _substring(info.level.name, 5);

      return '$levelString $formattedTime ${info.message}';
    };
  }

  static String _substring(String str, int maxLength) =>
      str.length <= maxLength ? str.padRight(maxLength) : str.substring(0, maxLength);

  /// convert an integer Debug level value into a Level variable
  /// if the int level is not valid, return Level.ALL
  static Level int2level(int level) {
    if (level >= 0 && level < Level.LEVELS.length) {
      return Level.LEVELS[level];
    } else {
      return _kDefaultLevel; // Default to INFO if invalid
    }
  }

  /// convert a level value into a int variable
  /// return -1 if not valid
  static int level2int(Level level) => Level.LEVELS.indexOf(level);

  static void setDebugLevel(Level level) => _simpleLogger.setLevel(level);

  static String _breakIntoLines(String str, [String indent = '']) {
    const int kMaxLineLength = 80;
    String currentString = indent;
    List<String> items = str.split(' ');
    List<String> lines = [];
    while (items.isNotEmpty) {
      while (currentString.length < kMaxLineLength && items.isNotEmpty) {
        currentString += '${items.removeAt(0)} ';
      }
      lines.add(currentString);
      currentString = indent; // next lines are indented
    }
    return lines.join('\n');
  }

  static String _objectToString(dynamic object, [String indent = '']) {
    if (object != null) {
      try {
        if (object is Map) {
          String data = indent;
          int num = 1;
          object.forEach((key, value) {
            data += '"$key": $value, ';
            if (num++ % 5 == 0) data += '\n$indent';
          });
          return data;
        } else {
          return _breakIntoLines(object.toString(), indent);
        }
      } catch (_) {}
    }
    return '';
  }

  static String _buildMessage(
    String heading,
    Object message,
    Object? myCustomObject,
    Object? exception,
    String indentation,
  ) {
    String str = '[$heading]$indentation$message';
    final String secondIndent = ' ' * 5;
    if (exception != null) str += '\n$secondIndent** EXCEPTION **\n${_breakIntoLines(str, secondIndent)}';
    if (myCustomObject != null) str += '\n$secondIndent** OBJECT **\n${_objectToString(myCustomObject, secondIndent)}';

    return str;
  }

  static void log(
    String heading,
    Object message, {
    Object? myCustomObject,
    Object? exception,
    Level level = _kDefaultLevel,
    bool indent = false,
    bool captureSentryMessage = false,
  }) {
    final String indentation = indent ? '     >> ' : ' ';
    final String logMessage = _buildMessage(heading, message, myCustomObject, exception, indentation);

    // show in Telegram
    if (level >= Level.WARNING) {
      sendMessageToTelegram('[$_loggedUserId]$logMessage', botType: BotType.error);
    }

    // show in console
    if (level >= _simpleLogger.level) _simpleLogger.log(level, logMessage);

    // show in Sentry
    SentryLevel sentryLevel = SentryLevel.info;
    switch (level) {
      case Level.SHOUT:
      case Level.SEVERE:
        sentryLevel = SentryLevel.error;
        break;
      case Level.WARNING:
        sentryLevel = SentryLevel.warning;
        break;
      case Level.INFO:
        sentryLevel = SentryLevel.info;
        break;
      default:
        sentryLevel = SentryLevel.debug;
    }

    if (captureSentryMessage || level >= Level.WARNING) {
      Sentry.captureMessage(logMessage, level: sentryLevel);
    } else {
      Sentry.addBreadcrumb(Breadcrumb(message: logMessage, level: sentryLevel));
    }
  }
}
