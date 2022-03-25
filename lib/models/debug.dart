import 'dart:developer' as developer;

import '../utilities/date.dart';
import '../utilities/http_helper.dart';

enum DebugType { basic, info, summary, error }

// singleton
class MyLog {
  static final MyLog _singleton = MyLog._internal();

  MyLog._internal();

  factory MyLog() => _singleton;

  final List<String> _logMsgList = [];

  static DebugType minDebugType = DebugType.basic; // minimum log to register

  static String loggedUserId = '';

  List<String> get logMsgList => _logMsgList;

  void get delete => _logMsgList.clear();

  void _log(String message, {required String heading, Object? error}) {
    String dateHeading = dateTimeToString(DateTime.now(), format: 'mm:ss ') + heading;
    String errorStr = error == null ? '' : '\nERROR: ${error.toString()}';

    developer.log(message, name: dateHeading, error: error);
    _logMsgList.add('[$dateHeading] $message $errorStr');
  }

  void log(String heading, dynamic message,
      {dynamic myCustomObject, dynamic exception, DebugType debugType = DebugType.basic}) {
    if (debugType.index >= MyLog.minDebugType.index) {
      if (debugType == DebugType.error) {
        String errorMsg = '\n******************\n****         *****'
            '\n****  ERROR  *****'
            '\n****         *****\n******************';
        _log(errorMsg, heading: heading);
        errorMsg = '$message';
        if (myCustomObject != null) errorMsg += '\nOBJECT\n' + myCustomObject.toString();
        if (exception != null) errorMsg += '\nEXCEPTION\n' + exception.toString();
        sendMessageToTelegram('[$loggedUserId:$heading]\n$errorMsg', botType: BotType.error);
      }

      _log(message, heading: heading);

      if (exception != null) _log(exception.toString(), heading: heading, error: exception);

      if (myCustomObject != null) {
        if (myCustomObject is List) {
          for (var item in myCustomObject) {
            _log(''.padLeft(heading.length + 2) + item.toString(), heading: '>');
          }
        } else if (myCustomObject is Map) {
          myCustomObject.forEach((k, v) => _log(
              ''.padLeft(heading.length + 2) + '[${k.toString()}]: ${v.toString()}',
              heading: '>'));
        } else {
          _log(''.padLeft(heading.length + 2) + myCustomObject.toString(), heading: '>');
        }
      }
    }
  }
}

// for sending a log message to telegram
//   final List<String> _telegramMsgList = [];
//  {
//     Timer.periodic(const Duration(seconds: 2), (timer) {
//       if (_telegramMsgList.isNotEmpty) {
//         String first = _telegramMsgList.removeAt(0);
//         sendMessageToTelegram(first, botType: BotType.log);
//       }
//     });
//   }
//  _telegramMsgList
//         .add('[$loggedUserId:$dateHeading (${_logMsgList.length})]\n$message $errorStr');
