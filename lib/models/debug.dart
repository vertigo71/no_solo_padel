import 'dart:async';

import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

import 'package:flutter_bugfender/flutter_bugfender.dart';
import '../utilities/http_helper.dart';

class MyLog {
  static final Logger _logger = Logger.root;

  /// initialize the logger
  static void initialize() {
    _logger.level = Level.ALL;
    _logger.onRecord.listen((LogRecord rec) {
      var timeFormat = DateFormat('HH:mm:ss'); // Format: Hour:Minute:Second
      String formattedTime = timeFormat.format(rec.time);

      print('[$formattedTime ${rec.level.name}]: ${rec.message}');
      if (rec.error != null) {
        print('  Error: ${rec.error}');
        if (rec.stackTrace != null) {
          print('${rec.stackTrace}');
        }
      }
    });
  }

  static String loggedUserId = '';

  // Level: ALL < FINEST < FINER < FINE < CONFIG < INFO < WARNING < SEVERE < SHOUT < OFF
  static List<Level> levels = [Level.ALL, Level.FINE, Level.INFO, Level.SEVERE];

  /// convert an integer Debug level value into a Level variable
  /// if the int level is not valid, return Level.ALL
  static Level int2level(int level) {
    if (level >= 0 && level < levels.length) {
      return levels[level];
    } else {
      return Level.ALL;
    }
  }

  /// convert a level value into a int variable
  /// return -1 if not valid
  static int level2int(Level level) => levels.indexOf(level);

  static void setDebugLevel(Level level) => _logger.level = level;

  static void log(String heading, Object message,
      {Object? myCustomObject, Object? exception, Level level = Level.FINE, bool indent = false}) {
    String indentation = indent ? '     >> ' : ' ';

    // show in Telegram
    if (level == Level.SEVERE) {
      String errorMsg = '\n******************'
          '\n****         *****'
          '\n****  ERROR  *****'
          '\n****         *****'
          '\n******************';
      errorMsg += '\n$message';
      if (myCustomObject != null) errorMsg += '\nOBJECT\n$myCustomObject';
      if (exception != null) errorMsg += '\nEXCEPTION\n$exception';
      sendMessageToTelegram('[$loggedUserId:$heading]\n$errorMsg', botType: BotType.error);
    }

    // show in console
    _logger.log(level, "[$heading]$indentation$message", exception);
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
          _logger.log(level, '$indentation$indentation$data');
        } else {
          _logger.log(level, '$indentation$indentation$myCustomObject');
        }
      } catch (_) {}
    }

    // show in BugFender
    Future<void> Function(String) logFunction = FlutterBugfender.info;
    if (level == Level.SEVERE) {
      logFunction = FlutterBugfender.error;
    } else if (level == Level.INFO) {
      logFunction = FlutterBugfender.warn;
    }
    logFunction('[$heading] $message'
        '${myCustomObject == null ? "" : "\nOBJECT: ${myCustomObject.toString()}"}'
        '${exception == null ? "" : "\nERROR: ${exception.toString()}"}');
  }

/*
  static void _log(String message, {required String heading, Object? error, required DebugType debugType}) {
    String errorStr = error == null ? '' : '\nERROR: ${error.toString()}';

    if (Environment().isDevelopment && debugType.index >= MyLog.minDebugType.index) {
      String dateHeading = dateTimeToString(DateTime.now(), format: 'HH:mm:ss ') + heading;
      developer.log("dev:$message", name: "name", time: DateTime.now(), level: debugType.index + 50, error: error);
      //xxx _logMsgList.add('[$dateHeading] $message $errorStr');
    }

    Future<void> Function(String) logFunction = FlutterBugfender.info;
    if (debugType == Level.SEVERE) {
      logFunction = FlutterBugfender.error;
    } else if (debugType == Level.INFO) {
      logFunction = FlutterBugfender.warn;
    }
    logFunction('[$heading] $message $errorStr');
  }
*/

/*
    //  show in console

    _log(message, heading: heading, debugType: level);

    if (exception != null) {
      _log(exception.toString(), heading: heading, error: exception, debugType: level);
    }

    if (myCustomObject != null) {
      if (myCustomObject is List) {
        for (var item in myCustomObject) {
          _log(''.padLeft(heading.length + 2) + item.toString(), heading: '>', debugType: level);
        }
      } else if (myCustomObject is Map) {
        myCustomObject.forEach((k, v) =>
            _log('${''.padLeft(heading.length + 2)}[${k.toString()}]: ${v.toString()}',
                heading: '>', debugType: level));
      } else {
        _log(''.padLeft(heading.length + 2) + myCustomObject.toString(), heading: '>', debugType: level);
      }
    }*/
}
