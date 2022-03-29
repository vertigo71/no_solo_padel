import 'dart:developer' as developer;

import 'package:flutter_bugfender/flutter_bugfender.dart';
import '../utilities/date.dart';
import '../utilities/environment.dart';
import '../utilities/http_helper.dart';

enum DebugType { info, warning, error }

// singleton
class MyLog {
  static final MyLog _singleton = MyLog._internal();

  MyLog._internal();

  factory MyLog() => _singleton;

  final List<String> _logMsgList = [];

  static DebugType minDebugType = DebugType.info; // minimum log to register

  static String loggedUserId = '';

  List<String> get logMsgList => _logMsgList;

  void get delete => _logMsgList.clear();

  void _log(String message,
      {required String heading, Object? error, required DebugType debugType}) {
    String errorStr = error == null ? '' : '\nERROR: ${error.toString()}';

    if (Environment().isDevelopment && debugType.index >= MyLog.minDebugType.index) {
      String dateHeading = dateTimeToString(DateTime.now(), format: 'HH:mm:ss ') + heading;
      developer.log(message, name: dateHeading, error: error);
      // _logMsgList.add('[$dateHeading] $message $errorStr');
    }

    Future<void> Function(String) logFunction = FlutterBugfender.info;
    if (debugType == DebugType.error) {
      logFunction = FlutterBugfender.error;
    } else if (debugType == DebugType.warning) {
      logFunction = FlutterBugfender.warn;
    }
    logFunction('[$heading] $message $errorStr');
  }

  void log(String heading, dynamic message,
      {dynamic myCustomObject, dynamic exception, DebugType debugType = DebugType.info}) {
    if (debugType == DebugType.error) {
      String errorMsg = '\n******************\n****         *****'
          '\n****  ERROR  *****'
          '\n****         *****\n******************';
      if ( Environment().isDevelopment) developer.log(errorMsg, name: heading);
      errorMsg += '\n$message';
      if (myCustomObject != null) errorMsg += '\nOBJECT\n' + myCustomObject.toString();
      if (exception != null) errorMsg += '\nEXCEPTION\n' + exception.toString();
      sendMessageToTelegram('[$loggedUserId:$heading]\n$errorMsg', botType: BotType.error);
    }

    _log(message, heading: heading, debugType: debugType);

    if (exception != null) {
      _log(exception.toString(), heading: heading, error: exception, debugType: debugType);
    }

    if (myCustomObject != null) {
      if (myCustomObject is List) {
        for (var item in myCustomObject) {
          _log(''.padLeft(heading.length + 2) + item.toString(),
              heading: '>', debugType: debugType);
        }
      } else if (myCustomObject is Map) {
        myCustomObject.forEach((k, v) => _log(
            ''.padLeft(heading.length + 2) + '[${k.toString()}]: ${v.toString()}',
            heading: '>',
            debugType: debugType));
      } else {
        _log(''.padLeft(heading.length + 2) + myCustomObject.toString(),
            heading: '>', debugType: debugType);
      }
    }
  }
}
