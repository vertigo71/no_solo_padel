import 'dart:async';
import 'package:intl/intl.dart';
import 'package:simple_logger/simple_logger.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';

import '../utilities/ut_http_helper.dart';

abstract class MyLog {
  static final SimpleLogger _simpleLogger = SimpleLogger();
  static String loggedUserId = '';

  /// initialize the logger
  static void initialize() {
    _simpleLogger.setLevel(Level.INFO);
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
      return Level.INFO; // Default to INFO if invalid
    }
  }

  /// convert a level value into a int variable
  /// return -1 if not valid
  static int level2int(Level level) => Level.LEVELS.indexOf(level);

  static void setDebugLevel(Level level) => _simpleLogger.setLevel(level);

  static void log(String heading, Object message,
      {Object? myCustomObject, Object? exception, Level level = Level.INFO, bool indent = false}) {
    final String indentation = indent ? '     >> ' : ' ';
    final String logMessage = "[$heading]$indentation$message";

    // show in Telegram
    if (level >= Level.WARNING) {
      String errorMsg = level == Level.SEVERE
          ? '\n******************'
              '\n**** ERROR  *****'
              '\n******************'
              '\n'
          : '';
      errorMsg += message.toString();
      if (myCustomObject != null) errorMsg += '\nOBJECT\n${myCustomObject.toString()}';
      if (exception != null) errorMsg += '\nEXCEPTION\n${exception.toString()}';

      sendMessageToTelegram('[$loggedUserId:$heading]\n$errorMsg', botType: BotType.error);
    }

    // show in console
    if (level >= _simpleLogger.level) {
      _simpleLogger.log(level, logMessage);

      if (exception != null) _simpleLogger.log(level, '** EXCEPTION ** ${exception.toString()}');

      if (myCustomObject != null) {
        try {
          if (myCustomObject is Map) {
            String data = "{\n\t";
            int num = 1;
            myCustomObject.forEach((key, value) {
              data += '"$key": $value ,';
              if (num++ % 5 == 0) data += '\n\t';
            });
            data += "\n}";
            _simpleLogger.log(level, '$indentation$indentation$data');
          } else {
            _simpleLogger.log(level, '$indentation$indentation$myCustomObject');
          }
        } catch (_) {}
      }
    }

    // show in BugFender
    Future<void> Function(String) logFunction;
    if (level >= Level.SEVERE) {
      logFunction = FlutterBugfender.error;
    } else if (level == Level.WARNING) {
      logFunction = FlutterBugfender.warn;
    } else {
      logFunction = FlutterBugfender.info;
    }
    logFunction('[$loggedUserId:$heading] $message'
        '${myCustomObject == null ? "" : "\nOBJECT: ${myCustomObject.toString()}"}'
        '${exception == null ? "" : "\nERROR: ${exception.toString()}"}');
  }
}
